#!/usr/bin/env python3
"""ghOSt notification history and standard FDO server, without name takeover.

If another server owns the name, observe new protocol messages and close through
the standard API. Become the independent server only when the name is vacant.
History stays in memory; only the user's DND preference is written locally.
"""
import html
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import sys
import time
import warnings

import gi
from gi.repository import Gio, GLib

NAME = 'org.freedesktop.Notifications'
PATH = '/org/freedesktop/Notifications'
XML = '''<node><interface name="org.freedesktop.Notifications">
<method name="GetCapabilities"><arg type="as" direction="out"/></method>
<method name="GetServerInformation"><arg type="s" direction="out"/><arg type="s" direction="out"/><arg type="s" direction="out"/><arg type="s" direction="out"/></method>
<method name="Notify"><arg type="s" direction="in"/><arg type="u" direction="in"/><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="as" direction="in"/><arg type="a{sv}" direction="in"/><arg type="i" direction="in"/><arg type="u" direction="out"/></method>
<method name="CloseNotification"><arg type="u" direction="in"/></method>
<signal name="NotificationClosed"><arg type="u"/><arg type="u"/></signal>
<signal name="ActionInvoked"><arg type="u"/><arg type="s"/></signal>
</interface></node>'''

class PlainText(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
    def handle_data(self, value):
        self.parts.append(value)
    def handle_starttag(self, tag, attrs):
        if tag in ('br', 'p'): self.parts.append('\n')

def plain(value, maximum=2000):
    parser = PlainText()
    parser.feed(str(value)[:8000])
    return html.unescape(''.join(parser.parts)).strip()[:maximum]

class History:
    def __init__(self):
        self.items = []
    def add(self, identifier, arguments, owner, owned):
        app, replaces, icon, summary, body, actions, hints, timeout = arguments
        key = owner + ':' + str(identifier)
        item = dict(key=key, id=identifier, app=plain(app,120) or 'Application',
                    summary=plain(summary,200), body=plain(body), time=int(time.time()),
                    owned=owned, active=True,
                    actions=[dict(key=actions[i],label=plain(actions[i+1],80))
                             for i in range(0,len(actions)-1,2)][:8])
        self.items = [item] + [old for old in self.items if old['key'] != key]
        self.items = self.items[:100]
        return item
    def close(self, identifier, owner):
        for item in self.items:
            if item['id'] == identifier and item['key'].startswith(owner+':'):
                item['active'] = False
    def remove(self, key):
        self.items = [item for item in self.items if item['key'] != key]

class Service:
    def __init__(self):
        self.history = History()
        self.pending = {}
        self.next_id = 1
        self.expiry = {}
        self.input_buffer = ''
        self.owned = False
        self.monitoring = False
        self.error = ''
        self.pref = Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config'))) / 'ghost/notifications.json'
        try: self.dnd = json.loads(self.pref.read_text()).get('dnd') is True
        except (OSError,ValueError): self.dnd = False
        self.connection = Gio.bus_get_sync(Gio.BusType.SESSION,None)
        self.unique = self.connection.get_unique_name()
        with warnings.catch_warnings():
            # PyGObject's callable override still uses this entry point on Arch.
            warnings.filterwarnings('ignore',message='Gio.DBusConnection.register_object is deprecated',category=DeprecationWarning)
            self.connection.register_object(PATH,Gio.DBusNodeInfo.new_for_xml(XML).interfaces[0],self.method,None,None)
        self.connection.signal_subscribe('org.freedesktop.DBus','org.freedesktop.DBus','NameOwnerChanged',
                                         '/org/freedesktop/DBus',NAME,Gio.DBusSignalFlags.NONE,self.owner_changed)
        self.acquire()
        try:
            self.monitor = Gio.DBusConnection.new_for_address_sync(
                Gio.dbus_address_get_for_bus_sync(Gio.BusType.SESSION,None),
                Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
                None,None)
            self.monitor.add_filter(self.message,None)
            matches = ["type='method_call',interface='org.freedesktop.Notifications'",
                       "type='method_return',sender='org.freedesktop.Notifications'", "type='error',sender='org.freedesktop.Notifications'",
                       "type='signal',interface='org.freedesktop.Notifications'"]
            self.monitor.call_sync('org.freedesktop.DBus','/org/freedesktop/DBus',
                'org.freedesktop.DBus.Monitoring','BecomeMonitor',GLib.Variant('(asu)',(matches,0)),
                None,Gio.DBusCallFlags.NONE,2000,None)
            self.monitoring = True
        except GLib.Error:
            self.error = 'Notification observation is unavailable while another service is active'
        GLib.io_add_watch(sys.stdin,GLib.IOCondition.IN | GLib.IOCondition.HUP,self.input)
        self.emit()
    def emit(self, toast=None):
        state = dict(ready=self.owned or self.monitoring,mode='server' if self.owned else 'observe',
                     dnd=self.dnd,items=self.history.items,error=self.error)
        if toast and not self.dnd and self.owned: state['toast'] = toast
        print(json.dumps(state,ensure_ascii=False),flush=True)
    def acquire(self):
        answer = self.connection.call_sync('org.freedesktop.DBus','/org/freedesktop/DBus',
            'org.freedesktop.DBus','RequestName',GLib.Variant('(su)',(NAME,4)),
            GLib.VariantType.new('(u)'),Gio.DBusCallFlags.NONE,2000,None).unpack()[0]
        self.owned = answer in (1,4)  # no replacement and DO_NOT_QUEUE
    def owner_changed(self,connection,sender,path,interface,signal,parameters):
        name,old,new = parameters.unpack()
        if not new:
            self.acquire()
            self.emit()
    def signal(self,name,value):
        self.connection.emit_signal(None,PATH,NAME,name,value)
    def close(self,identifier,reason=2):
        active = any(item['id']==identifier and item['owned'] and item['active'] for item in self.history.items)
        timer = self.expiry.pop(identifier,None)
        if timer: GLib.source_remove(timer)
        if not active: return GLib.SOURCE_REMOVE
        self.history.close(identifier,self.unique)
        self.signal('NotificationClosed',GLib.Variant('(uu)',(identifier,reason)))
        self.emit()
        return GLib.SOURCE_REMOVE
    def method(self,connection,sender,path,interface,method,parameters,invocation):
        values = parameters.unpack()
        if method == 'GetCapabilities':
            invocation.return_value(GLib.Variant('(as)',(['body','actions','persistence'],)))
        elif method == 'GetServerInformation':
            invocation.return_value(GLib.Variant('(ssss)',('ghOSt','ghOSt','0.4','1.2')))
        elif method == 'Notify':
            identifier = values[1]
            if not identifier or not any(item['id']==identifier and item['active'] for item in self.history.items):
                identifier = self.next_id
                self.next_id += 1
            item = self.history.add(identifier,values,self.unique,True)
            invocation.return_value(GLib.Variant('(u)',(identifier,)))
            self.emit(item)
            timer = self.expiry.pop(identifier,None)
            if timer: GLib.source_remove(timer)
            timeout = 6000 if values[7]<0 else values[7]
            if timeout>0: self.expiry[identifier] = GLib.timeout_add(timeout,self.expire,identifier)
        elif method == 'CloseNotification':
            self.close(values[0],3)
            invocation.return_value(None)
    def expire(self,identifier):
        self.expiry.pop(identifier,None)
        return self.close(identifier,1)
    def message(self,connection,message,incoming,data):
        if incoming:
            kind = message.get_message_type()
            if kind == Gio.DBusMessageType.METHOD_CALL and message.get_member() == 'Notify' and message.get_path()==PATH and message.get_signature()=='susssasa{sv}i' and not self.owned:
                GLib.idle_add(self.remember,message.get_sender(),message.get_serial(),message.get_body().unpack(),message.get_destination())
            elif kind in (Gio.DBusMessageType.METHOD_RETURN,Gio.DBusMessageType.ERROR):
                GLib.idle_add(self.reply,message.get_destination(),message.get_reply_serial(),message.get_sender(),message.get_body(),kind)
            elif kind == Gio.DBusMessageType.SIGNAL and message.get_member() == 'NotificationClosed' and not self.owned:
                GLib.idle_add(self.observed_close,message.get_sender(),message.get_body().unpack()[0])
        # Monitors must never let Gio dispatch an observed method and reply to it.
        # Preserve BecomeMonitor's own reply while initialising, then consume.
        initial_reply = message.get_message_type() in (Gio.DBusMessageType.METHOD_RETURN,Gio.DBusMessageType.ERROR) and message.get_sender()=='org.freedesktop.DBus' and not self.monitoring
        if incoming and not initial_reply:
            return None
        # Both callback input and output transfer ownership. Returning a distinct
        # copy avoids aliasing the same PyGObject wrapper during monitor setup.
        return message.copy()
    def remember(self,sender,serial,arguments,destination):
        self.pending[(sender,serial)] = (arguments,time.monotonic())
        self.pending = {key:value for key,value in list(self.pending.items())[-100:] if time.monotonic()-value[1]<15}
        return GLib.SOURCE_REMOVE
    def reply(self,destination,serial,owner,body,kind):
        pending = self.pending.pop((destination,serial),None)
        if pending and kind == Gio.DBusMessageType.METHOD_RETURN:
            values = body.unpack()
            if len(values)==1 and isinstance(values[0],int):
                self.history.add(values[0],pending[0],owner,False)
                self.emit()
        return GLib.SOURCE_REMOVE
    def observed_close(self,owner,identifier):
        self.history.close(identifier,owner)
        self.emit()
        return GLib.SOURCE_REMOVE
    def dismiss(self,item):
        if item['active']:
            if item['owned']: self.close(item['id'])
            else:
                self.connection.call(item['key'].rsplit(':',1)[0],PATH,NAME,'CloseNotification',
                    GLib.Variant('(u)',(item['id'],)),None,Gio.DBusCallFlags.NONE,2000,None,None,None)
        self.history.remove(item['key'])
    def command(self,value):
        if not isinstance(value,dict): raise ValueError('Invalid command')
        operation = value.get('operation')
        if operation == 'dnd' and isinstance(value.get('value'),bool):
            self.dnd = value['value']
            self.pref.parent.mkdir(parents=True,exist_ok=True)
            temporary = self.pref.with_suffix('.tmp')
            temporary.write_text(json.dumps({'dnd':self.dnd}))
            temporary.chmod(0o600)
            temporary.replace(self.pref)
        elif operation == 'dismiss':
            item = next((item for item in self.history.items if item['key']==value.get('key')),None)
            if item: self.dismiss(item)
        elif operation == 'clear':
            for item in list(self.history.items): self.dismiss(item)
        elif operation == 'action':
            item = next((item for item in self.history.items if item['key']==value.get('key')),None)
            action = value.get('action')
            if item and item['owned'] and item['active'] and any(a['key']==action for a in item['actions']):
                self.signal('ActionInvoked',GLib.Variant('(us)',(item['id'],action)))
                self.dismiss(item)
        self.emit()
    def input(self,source,condition):
        if condition & GLib.IOCondition.HUP:
            self.loop.quit()
            return GLib.SOURCE_REMOVE
        try:
            chunk = os.read(source.fileno(),65536)
            if not chunk:
                self.loop.quit()
                return GLib.SOURCE_REMOVE
            self.input_buffer += chunk.decode('utf-8')
            while '\n' in self.input_buffer:
                line,self.input_buffer = self.input_buffer.split('\n',1)
                if line.strip(): self.command(json.loads(line))
        except (ValueError,OSError,GLib.Error):
            self.error = 'Could not update notifications'
            self.emit()
        return GLib.SOURCE_CONTINUE
    def run(self):
        self.loop = GLib.MainLoop()
        self.loop.run()

if __name__ == '__main__':
    try: Service().run()
    except (GLib.Error,OSError) as error:
        print(json.dumps(dict(ready=False,items=[],dnd=False,error='Notification connection unavailable')),flush=True)
        sys.exit(1)
