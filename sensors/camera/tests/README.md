# Camera / video-acquisition tests

Hardware-free tests for the video-acquisition code in `sensors/camera/`.
They mock the camera, so **no Image Acquisition Toolbox and no FLIR camera
are required** — anyone can run them to verify the recording pipeline.

## What's tested

| File | Purpose |
|------|---------|
| `smokeTestFFmpegTransport.m` | End-to-end check of the ffmpeg recording path: drives the real `pushFramesToFFmpeg` through a real ffmpeg subprocess and verifies a readable `.mp4` is produced with frames in the correct byte order. |
| `FakeImaqCamera.m` | Minimal stand-in for an IMAQ `videoinput` object (exposes `FramesAvailable` and `getdata`). |

The smoke test writes a known marker pixel at an **asymmetric** coordinate
`(row=11, col=37)` into 64×48 frames and asserts it reads back at the same
coordinate. A column-major → row-major transpose bug in the frame transport
would surface as a swapped coordinate `(37,11)` and a dimension mismatch, so
this catches the one class of bug that can't be caught by reading the code.

## Requirements

- MATLAB (verified on R2023b) — only core MATLAB, no toolboxes.
- `ffmpeg` on the system `PATH` (verified with ffmpeg 8.1, `libx264`).
  - macOS: `brew install ffmpeg`
  - Windows: install ffmpeg and add its `bin` folder to `PATH`
  - Linux: `apt install ffmpeg` (or distro equivalent)

If ffmpeg is not found, the test reports a clear error and does not run.

## How to run

### From the MATLAB command window

```matlab
cd <repo>/sensors/camera/tests
smokeTestFFmpegTransport
```

The function adds the needed paths itself, so you can also just call
`smokeTestFFmpegTransport` from anywhere once the `tests` folder is on the path.

Expected output:

```
PASS: ffmpeg produced a non-empty file (1854 bytes)
PASS: file is readable, 10 frames, 64x48
PASS: dimensions preserved (64x48)
PASS: marker at (11,37) read back at (11,37) -- byte order correct

ALL CHECKS PASSED
```

The test **errors** (with a descriptive message) on any failed assertion.

### Headless / CI (returns a proper exit code)

From a shell, in the repo root:

```sh
matlab -batch "addpath('sensors/camera/tests'); runCameraTests"
```

`runCameraTests.m` runs every test, prints a PASS/FAIL summary, and calls
`exit(1)` on failure (and exits 0 on success), so it can be dropped straight
into CI.
