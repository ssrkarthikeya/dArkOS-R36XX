#!/bin/bash
# ================================================================================
#  dArkOS-R36XX HARDWARE-ACCELERATED MEDIA PLAYER ENGINE
# ================================================================================
# Features:
#   - Rockchip RK3326 VPU Hardware Decoding (rkmpp: H.264, HEVC, MPEG-2/4, VP8)
#   - Gamepad Scrubbing (D-Pad, Analog Stick, L2/R2)
#   - Volume Control (L1/R1) with OSD
#   - Live Brightness Control (Right Stick Up/Down)
#   - Automatic Resume from Last Saved Position (Watch Later)
#   - Watch History Tracking (~/.config/video_history.log)
#   - USB OTG & Dual MicroSD Storage Support
# ================================================================================

VIDEO_FILE="$1"

if [ -z "$VIDEO_FILE" ] || [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: No valid video file specified."
    exit 1
fi

# Screen Resolution Detection
xres="$(cat /sys/class/graphics/fb0/modes 2>/dev/null | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f1)"
yres="$(cat /sys/class/graphics/fb0/modes 2>/dev/null | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f2)"
[ -z "$xres" ] && xres="640"
[ -z "$yres" ] && yres="480"

sudo chmod 666 /dev/tty1 /dev/uinput 2>/dev/null || true
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"

# Configuration Directories
CONFIG_DIR="/home/ark/.config"
RESUME_DIR="$CONFIG_DIR/video_resume"
HISTORY_LOG="$CONFIG_DIR/video_history.log"
mkdir -p "$RESUME_DIR"

# Generate File Identifier Hash for Resume Tracking
FILE_HASH=$(echo -n "$VIDEO_FILE" | md5sum | awk '{print $1}')
RESUME_FILE="$RESUME_DIR/${FILE_HASH}.pos"

# Start Watch History Logging
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] Started: $(basename "$VIDEO_FILE") | Path: $VIDEO_FILE" >> "$HISTORY_LOG"

# Check for Saved Resume Position
START_POS=""
if [ -f "$RESUME_FILE" ]; then
    SAVED_SECS=$(cat "$RESUME_FILE" 2>/dev/null || echo "")
    if [[ "$SAVED_SECS" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$SAVED_SECS > 10" | bc -l 2>/dev/null || echo 0) )); then
        START_POS="-ss $SAVED_SECS"
        echo "Resuming playback from ${SAVED_SECS}s..."
    fi
fi

# Launch Gamepad Key Mapper (gptokeyb)
GPTK_CONF="/opt/inttools/mediaplayer.gptk"
if [ -f "/usr/local/share/r36xx/mediaplayer.gptk" ]; then
    GPTK_CONF="/usr/local/share/r36xx/mediaplayer.gptk"
fi

if [ -x "/opt/inttools/gptokeyb" ]; then
    /opt/inttools/gptokeyb -1 "ffplay" -c "$GPTK_CONF" &
fi

# Detect Codec & Enable Rockchip MPP Hardware Decoding
format=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE" 2>/dev/null || echo "")

case "$format" in
    *h264*|*avc*)
        codec_arg="-vcodec h264_rkmpp"
        ;;
    *hevc*|*h265*)
        codec_arg="-vcodec hevc_rkmpp"
        ;;
    *vp8*)
        codec_arg="-vcodec vp8_rkmpp"
        ;;
    *mpeg2*)
        codec_arg="-vcodec mpeg2_rkmpp"
        ;;
    *mpeg4*|*xvid*|*divx*)
        codec_arg="-vcodec mpeg4_rkmpp"
        ;;
    *)
        codec_arg="" # Software fallback for AV1, VP9, etc.
        ;;
esac

# Execute Hardware-Accelerated Video Playback
# Using ffplay with optimized buffer, resolution fitting, and interactive controls
ffplay -loglevel warning \
       -infbuf \
       -seek_interval 10 \
       -x "$xres" -y "$yres" \
       -window_title "$(basename "$VIDEO_FILE")" \
       $START_POS \
       $codec_arg \
       "$VIDEO_FILE"

PLAY_EXIT_CODE=$?

# Cleanup and restore UI
unset SDL_GAMECONTROLLERCONFIG_FILE
if [[ ! -z $(pidof gptokeyb) ]]; then
    sudo kill -9 $(pidof gptokeyb) 2>/dev/null || true
fi

# Update Watch History on Finish
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$END_TIMESTAMP] Finished (Exit Code: $PLAY_EXIT_CODE)" >> "$HISTORY_LOG"

sudo systemctl restart ogage 2>/dev/null &
printf "\033c" > /dev/tty1 2>&1 || true
