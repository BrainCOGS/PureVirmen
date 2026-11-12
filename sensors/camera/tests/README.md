# Camera / video-acquisition tests

Hardware-free tests for the video-acquisition code in `sensors/camera/`.
They mock the camera, so **no Image Acquisition Toolbox and no FLIR camera
are required** — anyone can run them to verify the recording pipeline.

## What's tested

| File | Purpose |
|------|---------|
| `smokeTestFFmpegTransport.m` | End-to-end check of the ffmpeg recording path: drives the real `pushFramesToFFmpeg` through a real ffmpeg subprocess and verifies a readable `.mp4` is produced with frames in the correct byte order. |
| `FakeImaqCamera.m` | Minimal stand-in for an IMAQ `videoinput` object (exposes `FramesAvailable` and `getdata`). |
| `testCameraRecording.m` | Checks initialization-time offsets, empty/single timelines, constant-rate frame timestamps, disk-logger flushing before deletion, and reporting of failed FFmpeg processes. |
| `testFFmpegEncoderFallback.m` | Runs the real `startVideoAcquisition` → `configureSingleCamera` → ffmpeg → `stopVideoAcquisition` path on a virtual camera. Checks the encoder preflight, the NVENC → libx264 fallback (forced with an encoder name no ffmpeg has, so it doesn't depend on the GPU), errors before recording when no encoder works, and the real `h264_nvenc` on this machine (either outcome passes). It reads each video back to check frame count, order and byte order. |
| `fixtures/private/virtualCamera/` | `videoinput`/`imaqreset` doubles and a `VirtualCamera` that "acquires" 17 frames and fires `FramesAcquiredFcn`. The private directory keeps these mocks out of `genpath(repo)` in real experiments. `testFFmpegEncoderFallback` temporarily takes the Image Acquisition Toolbox folders off the path; otherwise IMAQ's `videoinput` class takes precedence over the double. |

On the ffmpeg path, ffmpeg's output (preflights included) goes to
`<video name>.ffmpeg.log` next to the video (`v.logfile`). Nothing in MATLAB
drains a pipe, so frame writes and the wait at stop can't deadlock on a full
stderr buffer.

The smoke test writes a known marker pixel at an **asymmetric** coordinate
`(row=11, col=37)` into 64×48 frames and asserts it reads back at the same
coordinate. A column-major → row-major transpose bug in the frame transport
would surface as a swapped coordinate `(37,11)` and a dimension mismatch, so
this catches the one class of bug that can't be caught by reading the code.

## Requirements

- MATLAB (verified on R2023b) — only core MATLAB, no toolboxes.
- `ffmpeg` on the system `PATH` (verified with ffmpeg 8.1 and 9.0.2, `libx264`). `testFFmpegEncoderFallback` also adds the WinGet `Links` folder to `PATH` when ffmpeg was installed with WinGet.
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

Synchronization logs must include `timeElapsedFirstTrial` copied from
`vr.timeElapsedFirstTrial`, along with `timeElapsedVideoStart` and loop-relative
`iterationTimes`. Both clocks are then aligned to `vr.preTic`. Supplying
`frameTimes` uses camera timestamps relative to video start; otherwise frame
timestamps are reconstructed from the file frame rate and assume no drops.

Tests use small synthetic frames, not a FLIR camera or a mini rig. Encoder
preflight proves that encoding works, not that CPU fallback keeps up at a
rig's full resolution and frame rate; that needs an on-rig check.
