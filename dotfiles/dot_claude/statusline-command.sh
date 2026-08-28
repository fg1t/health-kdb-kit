#!/usr/bin/env bash
# Claude Code status line — mirrors zsh PROMPT style exactly:
# user@host [HH:MM:SS] ~/full/path (branch) | model·(CTX) | ctx:USED%/(CTX) | VIM MODE
#
# Catppuccin Mocha truecolor — matched to the starship prompt blocks:
#   #ffffff white     (apple + user@host — prompt chip)
#   #74c7ec sapphire  (timestamp — prompt clock block)
#   #89b4fa blue      (dir — prompt directory block)
#   #a6e3a1 green     (git branch — prompt git block)
#   #94e2d5 teal      (model label + duration — prompt "took")
#   #cdd6f4 text      (ctx)
#   #b4befe lavender  (vim mode — prompt jobs marker)
#   #6c7086 overlay0  (separators)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_id=$(echo "$input" | jq -r '.model.id // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Timestamp
ts=$(date +%H:%M:%S)

# user@host
user=$(whoami)
host=$(hostname -s)

# Full path with ~ for home (mirrors %~ — replace $HOME prefix with ~)
# Tilde via a variable: an unquoted ~ re-expands to $HOME (no-op), and
# a backslashed \~ stays literal on mac bash 3.2 — the variable form is inert on both.
tilde='~'
dir="${cwd/#$HOME/$tilde}"

# Git branch (skip optional locks to avoid blocking)
branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null)
    [ -n "$branch" ] && branch=" ($branch)"
fi

# Shorten model ID to a compact label
# Examples: claude-sonnet-4-6 → 4-6, claude-opus-4 → opus, claude-haiku-3-5 → haiku
short_model=""
if [ -n "$model_id" ]; then
    case "$model_id" in
        *opus*)
            # Extract version number after "opus": claude-opus-4 → opus 4, claude-opus-4-5 → opus 4-5
            ver=$(echo "$model_id" | sed 's/.*opus-//')
            short_model="opus ${ver}"
            ;;
        *sonnet*)
            # Extract version number after "sonnet": claude-sonnet-4-6 → sonnet 4-6
            ver=$(echo "$model_id" | sed 's/.*sonnet-//')
            short_model="sonnet ${ver}"
            ;;
        *haiku*)
            # Extract version number after "haiku": claude-haiku-3-5 → haiku 3-5
            ver=$(echo "$model_id" | sed 's/.*haiku-//')
            short_model="haiku ${ver}"
            ;;
        *)
            short_model="$model_id"
            ;;
    esac
fi

# Format context window size as human-readable (e.g. 200000 → 200K, 1000000 → 1M)
fmt_ctx_size() {
    local n=$1
    if [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        printf "%dM" $(( n / 1000000 ))
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        printf "%dK" $(( n / 1000 ))
    else
        printf "%d" "$n"
    fi
}

ctx_size_fmt=$(fmt_ctx_size "$ctx_size")

# Session duration — derived from transcript file birth time (macOS stat)
fmt_duration() {
    local mins=$1
    if [ "$mins" -lt 1 ] 2>/dev/null; then
        echo "<1min"
    elif [ "$mins" -lt 60 ] 2>/dev/null; then
        echo "${mins}mins"
    else
        local h=$(( mins / 60 ))
        local m=$(( mins % 60 ))
        echo "${h}h${m}m"
    fi
}

duration_str=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Birth time: Linux first (stat -c %W = birth epoch), mac fallback (stat -f %B).
    # Each candidate fully isolated — on GNU, `stat -f` means --file-system and
    # emits the fs table on STDOUT, so a naive `||` chain pollutes the capture.
    birth=$(stat -c %W "$transcript_path" 2>/dev/null)
    case "$birth" in ''|0|*[!0-9]*) birth=$(stat -f %B "$transcript_path" 2>/dev/null) ;; esac
    case "$birth" in ''|*[!0-9]*) birth="" ;; esac
    if [ -n "$birth" ]; then
        now=$(date +%s)
        elapsed_mins=$(( (now - birth) / 60 ))
        duration_str="[$(fmt_duration "$elapsed_mins")]"
    fi
fi

# ANSI colour helpers (256-colour) — One Half Dark palette
c_reset="\033[0m"
c_grey="\033[38;2;108;112;134m"   # separators — overlay0
c_teal="\033[38;2;148;226;213m"   # model label — Mocha teal
c_green="\033[38;2;166;227;161m"  # ctx low  (<50 %) — One Half Dark green (114); user@host uses 64 (Solarized)
c_yellow="\033[38;2;249;226;175m" # ctx mid  (50–79 %) — One Half Dark yellow (179)
c_orange="\033[38;2;243;139;168m" # ctx high (≥80 %) — One Half Dark red (203)

# Vim-mode colours — One Half Dark magenta (176)
c_vim_insert="\033[38;2;180;190;254m"   # magenta
c_vim_normal="\033[38;2;180;190;254m"   # magenta
c_vim_visual="\033[38;2;180;190;254m"   # magenta
c_vim_replace="\033[38;2;180;190;254m"  # magenta
c_dur="\033[38;2;148;226;213m"          # duration — same teal as model label

# Build | model·(CTX)[Xmins] section
# Format: grey separator + teal value + grey duration
model_part=""
if [ -n "$short_model" ]; then
    dur_suffix=""
    [ -n "$duration_str" ] && dur_suffix="${c_dur}${duration_str}${c_reset}"
    if [ -n "$ctx_size_fmt" ]; then
        model_part=" ${c_grey}|${c_reset} ${c_teal}${short_model}\xc2\xb7(${ctx_size_fmt})${c_reset}${dur_suffix}"
    else
        model_part=" ${c_grey}|${c_reset} ${c_teal}${short_model}${c_reset}${dur_suffix}"
    fi
fi

# Build | ctx:USED%/(CTX) section
# Fixed white colour regardless of usage level
c_ctx="\033[38;2;205;214;244m"  # Mocha text
ctx_part=""
if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
    if [ -n "$ctx_size_fmt" ]; then
        ctx_part=" ${c_grey}|${c_reset} ${c_ctx}ctx:${used_int}%/(${ctx_size_fmt})${c_reset}"
    else
        ctx_part=" ${c_grey}|${c_reset} ${c_ctx}ctx:${used_int}%${c_reset}"
    fi
fi

# Format token count as compact human-readable (e.g. 1234 → 1.2K, 1200000 → 1.2M)
fmt_tokens() {
    local n=$1
    if [ -z "$n" ] || [ "$n" = "null" ]; then echo ""; return; fi
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        printf "%.1fM" "$(echo "scale=1; $n / 1000000" | bc)"
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        printf "%.1fK" "$(echo "scale=1; $n / 1000" | bc)"
    else
        printf "%d" "$n"
    fi
}

# Build | in:X out:Y token usage section
# Colour: grey label, teal values — only shown when at least one count is present
c_tok="\033[38;2;112;177;255m"   # #70b1ff — matches directory block
tok_part=""
in_fmt=$(fmt_tokens "$total_input_tokens")
out_fmt=$(fmt_tokens "$total_output_tokens")
if [ -n "$in_fmt" ] || [ -n "$out_fmt" ]; then
    tok_str=""
    [ -n "$in_fmt" ]  && tok_str="in:${in_fmt}"
    [ -n "$out_fmt" ] && tok_str="${tok_str:+$tok_str }out:${out_fmt}"
    tok_part=" ${c_grey}|${c_reset} ${c_tok}${tok_str}${c_reset}"
fi

# Build vim mode section (colour per mode)
vim_part=""
if [ -n "$vim_mode" ]; then
    case "$vim_mode" in
        INSERT)       c_vim="$c_vim_insert"  ;;
        NORMAL)       c_vim="$c_vim_normal"  ;;
        VISUAL*)      c_vim="$c_vim_visual"  ;;
        REPLACE*)     c_vim="$c_vim_replace" ;;
        *)            c_vim="\033[38;2;180;190;254m"  ;;
    esac
    vim_part=" ${c_grey}|${c_reset} ${c_vim}${vim_mode}${c_reset}"
fi

# Order: user@host [HH:MM:SS] dir (branch) | model·(CTX) | ctx:USED%/(CTX) | VIM MODE
# The first four sections keep their original inline colour codes.
# The new sections (model_part, ctx_part, vim_part) carry their own colour codes,
# so we print them with %b to interpret backslash escapes.
apple=$(printf '\xef\xa3\xbf')
printf "\033[38;2;255;255;255m%s\033[0m \033[38;2;255;255;255m%s@%s\033[0m \033[38;2;116;199;236m[%s]\033[0m \033[38;2;112;177;255m%s\033[0m\033[38;2;166;227;161m%s\033[0m%b%b%b%b" \
    "$apple" "$user" "$host" "$ts" "$dir" "$branch" "$model_part" "$ctx_part" "$tok_part" "$vim_part"
