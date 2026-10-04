import importlib.util
import base64
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

root=Path(__file__).parents[1]/'config/quickshell/ghost-bar'
def module(name):
    spec=importlib.util.spec_from_file_location(name,root/(name+'.py'))
    value=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value
backend=module('settings_backend')
workspace=module('workspace_scroll')
capture=module('capture')

class Settings(unittest.TestCase):
    def setUp(self):
        self.directory=tempfile.TemporaryDirectory()
        self.env=patch.dict(os.environ,{'XDG_CONFIG_HOME':self.directory.name+'/config','XDG_STATE_HOME':self.directory.name+'/state'})
        self.env.start()
    def tearDown(self):
        self.env.stop()
        self.directory.cleanup()
    def test_tracking_off_by_default(self):
        self.assertFalse(backend.preferences()['usageTracking'])
        self.assertEqual(backend.usage()['seconds'],0)
        self.assertFalse(backend.paths()[1].exists())
    def test_preferences_are_independent_and_persistent(self):
        backend.setting('widgets.network','false')
        backend.setting('reducedMotion','true')
        self.assertFalse(backend.preferences()['widgets']['network'])
        self.assertTrue(backend.preferences()['reducedMotion'])
        self.assertEqual(backend.paths()[0].stat().st_mode&0o777,0o600)
    def test_unknown_or_wrong_typed_setting_rejected(self):
        for key,value in [('widgets.missing','true'),('wallpaper','true'),('usageTracking','yes')]:
            with self.assertRaises(ValueError):backend.setting(key,value)
        self.assertFalse(backend.paths()[0].exists())
    def test_corrupt_preferences_fall_back(self):
        for value in ([],{'widgets':3},{'usageTracking':'true'}):
            backend.save(backend.paths()[0],value)
            self.assertFalse(backend.preferences()['usageTracking'])
            self.assertTrue(backend.preferences()['widgets']['network'])
    def test_read_only_status_never_calls_setter(self):
        with patch.object(backend,'run',side_effect=OSError('unavailable')) as run:
            state=backend.status()
            self.assertIsNone(state['notifications'])
            self.assertIsNone(state['brightness'])
            self.assertIn('storage',state)
            for call in run.call_args_list:
                self.assertNotIn('set',call.args[0])
    def test_brightness_rejects_invalid_without_action(self):
        for value in ('-1','0','101','nan','inf','not a number'):
            with patch.object(backend,'run') as run:
                with self.assertRaises(ValueError):backend.action('brightness',value)
                run.assert_not_called()
    def test_brightness_is_bounded_argument_vector(self):
        with patch.object(backend,'run') as run:
            backend.action('brightness','69')
            run.assert_called_once_with(['brightnessctl','set','69%'])
    def test_local_image_validation_and_url_spaces(self):
        image=Path(self.directory.name)/'sample image.png'
        image.write_bytes(b'fixture')
        self.assertEqual(backend.wallpaper_path(image.as_uri()),image)
        for value in ('https://example.com/picture.png','file://remote/picture.png',str(image.with_suffix('.sh'))):
            with self.assertRaises(ValueError):backend.wallpaper_path(value)
    def test_wallpaper_saved_only_after_success(self):
        image=Path(self.directory.name)/'image.png';image.write_bytes(b'fixture')
        with patch.object(backend,'run',side_effect=ValueError('awww unavailable')):
            with self.assertRaises(ValueError):backend.action('wallpaper',str(image))
        self.assertNotIn('wallpaper',backend.preferences())
    def test_no_notification_owner_no_action(self):
        with patch.object(backend,'status',return_value={'notifications':None}),patch.object(backend,'run') as run:
            with self.assertRaises(ValueError):backend.action('dnd','true')
            run.assert_not_called()
    def test_dnd_sets_explicit_state_not_toggle(self):
        with patch.object(backend,'status',return_value={'notifications':{}}),patch.object(backend,'run') as run:
            backend.action('dnd','true');backend.action('dnd','false')
            self.assertEqual([c.args[0][-1] for c in run.call_args_list],['-dn','-df'])
    def test_unknown_action_is_rejected(self):
        with patch.object(backend,'run') as run:
            with self.assertRaises(ValueError):backend.action('reboot','')
            run.assert_not_called()
    def test_hostname_invalid_input_never_dispatches(self):
        for value in ('', '--reboot', 'name with spaces', 'UPPERCASE', '-edge', 'edge-', 'x'*64, 'host\n'):
            with self.subTest(value=value), patch.object(backend, 'run') as run:
                with self.assertRaises(ValueError):backend.action('hostname', value)
                run.assert_not_called()
    def test_hostname_is_explicit_bounded_argument_vector(self):
        with patch.object(backend, 'run') as run:
            backend.action('hostname', 'unit-001')
            run.assert_called_once_with(['hostnamectl','--no-ask-password','--static','hostname','unit-001'])
        self.assertFalse(backend.paths()[0].exists())
    def test_profile_copy_preserves_original_and_preferences(self):
        image=Path(self.directory.name)/'my picture.png'
        data=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aFfsAAAAASUVORK5CYII=')
        image.write_bytes(data)
        backend.setting('widgets.network','false')
        with patch.object(backend,'run') as run:
            backend.action('profile-picture',image.as_uri())
            run.assert_not_called()
        selected=Path(backend.unquote(backend.urlparse(backend.preferences()['profilePicture']).path))
        self.assertNotEqual(selected,image)
        self.assertEqual(selected.read_bytes(),data)
        self.assertEqual(image.read_bytes(),data)
        self.assertEqual(selected.stat().st_mode&0o777,0o600)
        self.assertFalse(backend.preferences()['widgets']['network'])
        backend.action('profile-picture',image.as_uri())
        self.assertEqual(len(list(selected.parent.glob('*.png'))),1)
    def test_profile_rejects_nonimage_and_remote_without_preference_change(self):
        image=Path(self.directory.name)/'not-image.png';image.write_bytes(b'not an image')
        for value in (str(image),'https://example.com/picture.png','file://remote/image.png'):
            with self.subTest(value=value), patch.object(backend,'run') as run:
                with self.assertRaises(ValueError):backend.action('profile-picture',value)
                run.assert_not_called()
        self.assertNotIn('profilePicture',backend.preferences())
    def test_failed_hostname_does_not_fake_new_name(self):
        with patch.object(backend,'run',side_effect=ValueError('Permission denied')):
            with self.assertRaises(ValueError):backend.action('hostname','unit-002')
        self.assertFalse(backend.paths()[0].exists())
    def test_history_counts_only_observed_display_on_intervals(self):
        backend.setting('usageTracking','true')
        with patch.object(backend.time,'time',side_effect=[100,160,220]),patch.object(backend,'battery',return_value=None),patch.object(backend,'run',side_effect=[json.dumps([{'dpmsStatus':True}]),json.dumps([{'dpmsStatus':False}])]):
            backend.usage(True);backend.usage(True);backend.usage(True)
        self.assertEqual(backend.usage()['seconds'],60)
    def test_history_never_backfills_suspension(self):
        backend.setting('usageTracking','true')
        with patch.object(backend.time,'time',side_effect=[100,1000]),patch.object(backend,'battery',return_value=None),patch.object(backend,'run') as run:
            backend.usage(True);backend.usage(True)
            run.assert_not_called()
        self.assertEqual(backend.usage()['seconds'],0)

class WorkspaceRing(unittest.TestCase):
    def test_empty_desktops_are_included(self):
        self.assertEqual(workspace.choose(1,1,[],3),4)
        self.assertEqual(workspace.choose(5,1,[]),1)
    def test_higher_only_populated(self):
        data=[{'id':6,'windows':0},{'id':8,'windows':2}]
        self.assertEqual(workspace.choose(5,1,data),8)
        self.assertEqual(workspace.choose(8,1,data),1)
    def test_open_empty_higher_can_exit_both_directions(self):
        self.assertEqual(workspace.choose(6,1,[]),1)
        self.assertEqual(workspace.choose(6,-1,[]),5)
    def test_multi_notches_wrap(self):
        self.assertEqual(workspace.choose(1,-1,[],2),4)
        self.assertEqual(workspace.choose(4,1,[],4),3)
    def test_special_workspaces_ignored(self):
        self.assertEqual(workspace.choose(5,1,[{'id':-99,'windows':2}]),1)

class Capture(unittest.TestCase):
    def test_region_and_negative_coordinates(self):
        self.assertEqual(capture.geometry('-1920,12 800x600\n'),'-1920,12 800x600')
    def test_invalid_regions_rejected(self):
        for value in ('0,0 0x1','0,0 -1x2','--help','0,0 5x5\nextra'):
            with self.assertRaises(ValueError):capture.geometry(value)

if __name__=='__main__':unittest.main()
