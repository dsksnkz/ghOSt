"""Private-session-bus regression tests; never contact the user's desktop bus."""
import importlib.util
import json
import os
from pathlib import Path
import queue
import subprocess
import tempfile
import threading
import time
import unittest

SOURCE = Path(__file__).resolve().parents[1]/'config/quickshell/ghost-bar/notifications.py'
spec = importlib.util.spec_from_file_location('notifications',SOURCE)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class Bridge:
    def __init__(self,env):
        self.process = subprocess.Popen(['python3',str(SOURCE)],env=env,
            stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.events = queue.Queue()
        self.reader = threading.Thread(target=self.read,daemon=True)
        self.reader.start()
    def read(self):
        for line in self.process.stdout:
            self.events.put(json.loads(line))
    def wait(self,predicate):
        deadline = time.monotonic()+5
        while time.monotonic()<deadline:
            try: state=self.events.get(timeout=max(.01,deadline-time.monotonic()))
            except queue.Empty: break
            if predicate(state): return state
        raise AssertionError('Notification state not received')
    def send(self,**value):
        self.process.stdin.write(json.dumps(value)+'\n');self.process.stdin.flush()
    def stop(self):
        self.process.stdin.close()
        self.process.wait(timeout=3)
        error=self.process.stderr.read()
        self.process.stdout.close();self.process.stderr.close()
        if error: raise AssertionError(error)

class NotificationsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ghost-notifications-')
        self.daemon = subprocess.Popen(['dbus-daemon','--session','--nofork','--print-address=1'],
            stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        address=self.daemon.stdout.readline().strip()
        self.env=dict(os.environ,DBUS_SESSION_BUS_ADDRESS=address,XDG_CONFIG_HOME=self.temp.name)
        self.bridges=[]
    def tearDown(self):
        for bridge in reversed(self.bridges): bridge.stop()
        self.daemon.terminate();self.daemon.wait(timeout=3)
        self.daemon.stdout.close();self.daemon.stderr.close();self.temp.cleanup()
    def start(self):
        bridge=Bridge(self.env);self.bridges.append(bridge)
        return bridge,bridge.wait(lambda state:state.get('ready'))
    def call(self,method,*values,dest='org.freedesktop.Notifications',path='/org/freedesktop/Notifications'):
        return subprocess.check_output(['gdbus','call','--session','--dest',dest,'--object-path',path,
            '--method',method,*values],env=self.env,text=True,timeout=3).strip()
    def notify(self,replaces='0',timeout='0',actions='[]'):
        reply=self.call('org.freedesktop.Notifications.Notify','ghOSt test',replaces,'','Test notice',
            '<b>Plain</b> body',actions,'{}',timeout)
        return reply.split('uint32 ')[-1].split(',')[0].strip('() ')
    def test_plain_text_and_bounded_history(self):
        self.assertEqual(module.plain('<b>A</b><br>B &amp; C'),'A\nB & C')
        history=module.History()
        for i in range(102): history.add(i,['App',0,'','Title','Body',[],{},0],':1.1',True)
        self.assertEqual(len(history.items),100)
        history.add(101,['App',101,'','Replacement','Body',[],{},0],':1.1',True)
        self.assertEqual(len(history.items),100)
        self.assertEqual(history.items[0]['summary'],'Replacement')
    def test_forwarded_filter_message_has_independent_ownership(self):
        service = module.Service.__new__(module.Service)
        service.monitoring = False
        message = module.Gio.DBusMessage.new_method_call(
            'org.freedesktop.DBus', '/org/freedesktop/DBus',
            'org.freedesktop.DBus', 'GetId')
        forwarded = service.message(None, message, False, None)
        self.assertIsNot(forwarded, message)
        self.assertEqual(forwarded.get_member(), message.get_member())
        self.assertEqual(forwarded.get_message_type(), message.get_message_type())
    def test_server_replacement_expiry_dnd_and_clear(self):
        bridge,state=self.start();self.assertEqual(state['mode'],'server')
        identifier=self.notify()
        state=bridge.wait(lambda state:len(state['items'])==1)
        self.assertEqual(state['items'][0]['body'],'Plain body');self.assertIn('toast',state)
        self.assertEqual(self.notify(identifier),identifier)
        bridge.wait(lambda state:len(state['items'])==1)
        bridge.send(operation='dnd',value=True)
        bridge.wait(lambda state:state['dnd'])
        self.notify(timeout='100')
        state=bridge.wait(lambda state:len(state['items'])==2)
        self.assertNotIn('toast',state)
        bridge.wait(lambda state:any(not item['active'] for item in state['items']))
        bridge.send(operation='clear')
        bridge.wait(lambda state:not state['items'])
        self.assertTrue(json.loads((Path(self.temp.name)/'ghost/notifications.json').read_text())['dnd'])
    def test_observer_preserves_owner_and_standard_dismissal(self):
        owner,_=self.start()
        before=self.call('org.freedesktop.DBus.GetNameOwner','org.freedesktop.Notifications',
            dest='org.freedesktop.DBus',path='/org/freedesktop/DBus')
        observer,state=self.start();self.assertEqual(state['mode'],'observe')
        identifier=self.notify()
        state=observer.wait(lambda state:len(state['items'])==1)
        self.assertFalse(state['items'][0]['owned'])
        self.assertNotIn('toast',state)
        after=self.call('org.freedesktop.DBus.GetNameOwner','org.freedesktop.Notifications',
            dest='org.freedesktop.DBus',path='/org/freedesktop/DBus')
        self.assertEqual(before,after)
        observer.send(operation='dismiss',key=state['items'][0]['key'])
        observer.wait(lambda state:not state['items'])
        owner.wait(lambda state:len(state['items'])==1 and not state['items'][0]['active'])
    def test_owned_actions_and_takeover_only_after_vacancy(self):
        owner,_=self.start();observer,state=self.start()
        identifier=self.notify(actions="['open', 'Open']")
        state=owner.wait(lambda state:len(state['items'])==1)
        owner.send(operation='action',key=state['items'][0]['key'],action='open')
        owner.wait(lambda state:not state['items'])
        owner.stop();self.bridges.remove(owner)
        observer.wait(lambda state:state['mode']=='server')
        self.notify()
        observer.wait(lambda state:any(item['owned'] for item in state['items']))

if __name__=='__main__': unittest.main()
