import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "config/quickshell/ghost-bar/storage_scan.py"
spec = importlib.util.spec_from_file_location("storage_scan", SOURCE)
storage_scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(storage_scan)


def write(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Flushed below, because btrfs reports no blocks for unwritten data.
    path.write_bytes(b"x" * size)
    os.sync()


class StorageScan(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ghost-storage-", dir=Path.home() / ".cache")
        self.root = Path(self.directory.name)
        self.addCleanup(self.directory.cleanup)

    def test_sizes_roll_up_and_largest_comes_first(self):
        write(self.root / "small/a.bin", 2 * 1024 * 1024)
        write(self.root / "big/deep/b.bin", 5 * 1024 * 1024)
        tree = storage_scan.scan(self.root)["tree"]
        self.assertEqual([child["n"] for child in tree["c"]], ["big", "small"])
        big = tree["c"][0]
        self.assertGreaterEqual(big["s"], 5 * 1024 * 1024)
        self.assertEqual(big["c"][0]["n"], "deep")
        self.assertEqual(big["c"][0]["c"][0]["n"], "b.bin")
        self.assertGreaterEqual(tree["s"], 7 * 1024 * 1024)

    def test_small_items_are_summed_not_listed(self):
        write(self.root / "tiny.bin", 8192)
        tree = storage_scan.scan(self.root)["tree"]
        self.assertEqual(tree["c"], [])
        self.assertEqual(tree["m"], 1)
        self.assertEqual(tree["o"], tree["s"])

    def test_symlinks_are_not_followed_and_hard_links_count_once(self):
        target = self.root / "real/data.bin"
        write(target, 3 * 1024 * 1024)
        (self.root / "link").symlink_to(self.root / "real")
        os.link(target, self.root / "real/again.bin")
        tree = storage_scan.scan(self.root)["tree"]
        self.assertLess(tree["s"], 4 * 1024 * 1024)

    @unittest.skipIf(os.geteuid() == 0, "root reads everything")
    def test_unreadable_folders_are_counted_and_do_not_stop_the_scan(self):
        locked = self.root / "locked"
        locked.mkdir()
        write(self.root / "open.bin", 2 * 1024 * 1024)
        locked.chmod(0)
        self.addCleanup(locked.chmod, 0o755)
        result = storage_scan.scan(self.root)
        self.assertEqual(result["unreadable"], 1)
        self.assertEqual(result["tree"]["c"][0]["n"], "open.bin")


class EmptyFolder(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ghost-empty-")
        self.home = Path(self.directory.name).resolve()
        self.addCleanup(self.directory.cleanup)
        previous = os.environ.get("HOME")
        os.environ["HOME"] = str(self.home)
        self.addCleanup(os.environ.__setitem__, "HOME", previous)

    def test_deletes_contents_and_keeps_the_folder(self):
        folder = self.home / "junk"
        write(folder / "deep/a.bin", 10)
        write(folder / "b.bin", 10)
        self.assertEqual(storage_scan.empty_folder(folder), (2, 0))
        self.assertEqual(list(folder.iterdir()), [])

    def test_a_symlink_inside_is_removed_but_its_target_survives(self):
        keep = self.home / "keep/file.bin"
        write(keep, 10)
        folder = self.home / "junk"
        folder.mkdir()
        (folder / "link").symlink_to(self.home / "keep")
        storage_scan.empty_folder(folder)
        self.assertTrue(keep.exists())
        self.assertEqual(list(folder.iterdir()), [])

    def test_refuses_home_outside_protected_and_symlinked_paths(self):
        outside = tempfile.TemporaryDirectory(prefix="ghost-outside-")
        self.addCleanup(outside.cleanup)
        write(Path(outside.name) / "file.bin", 10)
        (self.home / "via").symlink_to(outside.name)
        (self.home / ".config").mkdir()
        write(self.home / ".config/file", 10)
        for path in (self.home, Path(outside.name), self.home / "via", self.home / "via/.",
                     self.home / ".config", self.home / "missing", self.home / "x/../.config"):
            with self.assertRaises(ValueError, msg=str(path)):
                storage_scan.empty_folder(path)
        self.assertTrue((Path(outside.name) / "file.bin").exists())
        self.assertTrue((self.home / ".config/file").exists())


if __name__ == "__main__":
    unittest.main()
