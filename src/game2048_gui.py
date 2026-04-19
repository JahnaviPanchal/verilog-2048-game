# game2048_gui.py
import subprocess
import threading
import tkinter as tk
from tkinter import messagebox
import shutil
import sys
import time

# Check vvp availability
if shutil.which("vvp") is None:
    print("Error: 'vvp' not found in PATH. Please install Icarus Verilog and ensure vvp is available.")
    sys.exit(1)

# Start the simulator (expects game2048.out to exist)
proc = subprocess.Popen(
    ["vvp", "game2048.out"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

# Tkinter setup
root = tk.Tk()
root.title("2048 (Verilog)")

# Score label
score_var = tk.StringVar(value="Score: 0")
score_label = tk.Label(root, textvariable=score_var, font=("Arial", 16, "bold"))
score_label.pack(pady=(8,0))

# Board frame
board_frame = tk.Frame(root, bg="#bbada0")
board_frame.pack(padx=10, pady=10)

# Tile colors and labels
COLORS = {
    0:  ("#cdc1b4", "#776e65"),
    2:  ("#eee4da", "#776e65"),
    4:  ("#ede0c8", "#776e65"),
    8:  ("#f2b179", "#f9f6f2"),
    16: ("#f59563", "#f9f6f2"),
    32: ("#f67c5f", "#f9f6f2"),
    64: ("#f65e3b", "#f9f6f2"),
    128:("#edcf72", "#f9f6f2"),
    256:("#edcc61", "#f9f6f2"),
    512:("#edc850", "#f9f6f2"),
    1024:("#edc53f", "#f9f6f2"),
    2048:("#edc22e", "#f9f6f2"),
}

cells = [[None]*4 for _ in range(4)]
for r in range(4):
    for c in range(4):
        lbl = tk.Label(board_frame, text="", width=6, height=3,
                       font=("Arial", 24, "bold"),
                       bg="#cdc1b4", fg="#776e65",
                       relief="raised", bd=4)
        lbl.grid(row=r, column=c, padx=6, pady=6)
        cells[r][c] = lbl

# Parser state
board_buffer = None
current_score = 0

# Update GUI board
def update_gui_board(board_list):
    # board_list is length-16 list row-major
    for r in range(4):
        for c in range(4):
            val = int(board_list[r*4 + c])
            bg, fg = COLORS.get(val, ("#3c3a32", "#f9f6f2"))
            cells[r][c]["text"] = "" if val == 0 else str(val)
            cells[r][c]["bg"] = bg
            cells[r][c]["fg"] = fg

# Background reader: parse lines from Verilog stdout
def reader_thread():
    global board_buffer, current_score
    try:
        for rawline in proc.stdout:
            if rawline is None:
                break
            line = rawline.strip()
            if line == "":
                continue

            # Debug (optional)
            # print("VERILOG:", line)

            # Machine tokens:
            if line.startswith("BOARD"):
                parts = line.split()
                # expected 17 tokens: BOARD + 16 numbers
                if len(parts) >= 17:
                    nums = parts[1:17]
                    update_gui_board(nums)
                else:
                    # If not full, ignore
                    pass

            elif line.upper().startswith("SCORE"):
                # SCORE <n> OR "SCORE <n>" printed earlier as well
                parts = line.split()
                if len(parts) >= 2:
                    try:
                        current_score = int(parts[1])
                        score_var.set(f"Score: {current_score}")
                    except:
                        pass

            elif line.upper() == "WIN":
                # show popup and optionally stop sending input
                # update GUI one last time and inform user
                messagebox.showinfo("You Win!", "🎉 YOU WIN! (2048 reached)")
                # terminate simulation process (it usually finishes)
                # proc.terminate()
                # break

            elif line.upper() == "LOSE":
                messagebox.showerror("You Lose", "😢 No more possible moves. Game over.")
                # proc.terminate()
                # break

            else:
                # not a machine token: could be ASCII board lines; ignore
                pass

    except Exception as e:
        print("Reader thread exception:", e)

# Start reader thread
threading.Thread(target=reader_thread, daemon=True).start()

# Send move to Verilog
def send_move(ch):
    try:
        if proc.poll() is not None:
            # process exited
            return
        proc.stdin.write(ch + "\n")
        proc.stdin.flush()
    except Exception as e:
        print("Failed to send move:", e)

# Key handler for arrow keys and WASD and q
def on_key(event):
    key = event.keysym.lower()
    if key in ("up", "w"):
        send_move("w")
    elif key in ("down", "s"):
        send_move("s")
    elif key in ("left", "a"):
        send_move("a")
    elif key in ("right", "d"):
        send_move("d")
    elif key == "q":
        send_move("q")
        # close GUI
        try:
            proc.terminate()
        except:
            pass
        root.quit()

root.bind("<Key>", on_key)

# Graceful shutdown: ensure simulator killed
def on_close():
    try:
        if proc.poll() is None:
            try:
                proc.terminate()
                time.sleep(0.1)
            except:
                pass
    finally:
        root.destroy()

root.protocol("WM_DELETE_WINDOW", on_close)

# Start GUI loop
root.mainloop()