#!/usr/bin/env python3
"""Check native frame coverage, projection geometry and the encoded film."""
import json
import subprocess

import numpy as np
from PIL import Image

import film


def check():
    for sequence, count in [('wheel', 90), ('volume', 66),
                            ('calendar-framed', 150), ('sidebar', 90)]:
        for index in range(count):
            path = film.ASSETS / sequence / f'{index:04d}.png'
            with Image.open(path) as frame:
                frame.verify()
        print(f'{sequence}: {count} valid native frames')

    corners = np.array([(0, 0), (100, 0), (100, 50), (0, 50)])
    coefficients = film.perspective_coefficients(corners, corners)
    np.testing.assert_allclose(coefficients, [1, 0, 0, 0, 1, 0, 0, 0], atol=1e-10)
    np.testing.assert_allclose(film.rotation(0, 0, 0), np.eye(3))
    assert film.SCENES[0][0] == 0
    assert film.SCENES[-1][1] == film.DURATION
    for first, second in zip(film.SCENES, film.SCENES[1:]):
        assert first[1] == second[0], 'Gap in timeline'

    result = subprocess.run(
        ['ffprobe', '-v', 'error', '-show_streams', '-show_format',
         '-of', 'json', str(film.OUTPUT)],
        check=True, capture_output=True, text=True)
    info = json.loads(result.stdout)
    video = next(stream for stream in info['streams'] if stream['codec_type'] == 'video')
    audio = next(stream for stream in info['streams'] if stream['codec_type'] == 'audio')
    assert (video['width'], video['height']) == (film.WIDTH, film.HEIGHT)
    assert video['r_frame_rate'] == '30/1'
    assert int(video['nb_frames']) == film.FPS * film.DURATION
    assert float(info['format']['duration']) == film.DURATION
    assert audio['codec_name'] == 'aac'
    print('Projection, continuous timeline, resolution, frame count and audio: OK')


if __name__ == '__main__':
    check()
