# Lab 1: FSD, but on Kigali roads

A Full Self Driving (FSD) logic for a car that drives from **ALU Rwanda** to the
**Kigali Convention Centre**. The road is a Python list, and each item is one
100 m segment that may carry a sign. The provided web page shows the car
driving through Kigali at night, using only what the Python code decides.

## Files

| File | Role |
| --- | --- |
| `road_simulation.py` | **My work**: TODO 1-10 implemented |
| `analyze_log.sh` | **My work**: optional Bash log analyser |
| `transit_program.py` | Provided, not edited: runs the simulation loop and road editor |
| `engine.py` | Provided, not edited: small web server and shared state |
| `index.html` | Provided, not edited: the visual page |

## Requirements

- Python 3.8+ (standard library only, no external packages)
- Bash (Git Bash on Windows) for `analyze_log.sh`
- A web browser

## How to run

```bash
git clone https://github.com/fndegeya/lab1_fndegeya.git
cd lab1_fndegeya
python road_simulation.py      # or python3 road_simulation.py
```

1. Enter a driver name (max 14 characters, defaults to `Driver`).
2. Use the road editor menu (type a number from 1 to 5):
   - `1` add a sign at the end, `2` insert at a segment, `3` replace at an index,
     `4` show the road, `5` start driving.
   - Allowed signs: `bus`, `zebra`, or a speed limit from `20` to `100` (e.g. `80`).
3. After choosing `5`, open the printed link (e.g. http://127.0.0.1:8008).
4. Go back to the terminal and press **Enter**. The car starts to drive.

## The road data

| Item | Meaning |
| --- | --- |
| `"60"`, `"80"`, ... | Speed limit sign (stored as **text**), new limit for the car |
| `"zebra"` | Zebra crossing: the car stops for `ZEBRA_WAIT` seconds, then continues |
| `"bus"` | A bus is in the right lane: the car moves to the left lane |
| `"road"` | Plain road: nothing happens |

## What each function does

### Part 1: Check the sign
- **`is_valid_sign(sign)`**: `True` only for text that is `"bus"`, `"zebra"` or a
  whole number from 20 to 100. Non-strings (e.g. `80` as an int), negatives,
  decimals, empty text and other words are rejected. `str.isdecimal()` is used
  before `int()` so the conversion can never crash.
- **`get_sign_type(sign)`**: returns `"bus"`, `"zebra"`, `"speed"` or `"road"`.

### Part 2: Take action
- **`get_speed_limit(sign, current_limit)`**: converts a valid speed sign (20-100)
  to `int`, otherwise keeps the current limit (so `"150"` is ignored).
- **`get_target_speed(limit, stop_timer)`**: `0` while waiting at a zebra, else the limit.
- **`adjust_speed(speed, target)`**: one step per second: `+5` (ACCELERATION)
  when below, `-20` (BRAKING) when above, clamped so it never overshoots.
- **`count_signs(road_list)`**: a `for` loop that returns
  `(speed_signs, zebras, buses)`.

### Part 3: Safe input and journey summary
- **`ask_for_number(question, low, high)`**: keeps asking until the input is a
  whole number in range, using `try/except ValueError`. Each mistake gets its
  own message, for example:
  ```
  Error: 'abc' is not a whole number. Type digits only, e.g. 0 or 34.
  Error: 99 is out of range. Choose a number from 0 to 34.
  Error: you did not type anything. Enter a whole number from 1 to 5 (e.g. 1).
  ```
  If input is closed (Ctrl+C / end of file) it exits cleanly instead of looping.
- **`insert_sign(road_list, sign, position)`**: checks the position is a whole
  number (not `True`/`False`) from `0` to `len(road_list)` and the sign is valid,
  then inserts and returns `True`; otherwise `False`.
- **`replace_sign(road_list, sign, index)`**: same checks with the range `0` to
  `len(road_list) - 1`, then replaces and returns `True`; otherwise `False`.
- **`get_journey_summary(road_list)`**: loops to count every segment that is not
  plain road, computes `length_m = len(road_list) * SEGMENT_M`, and returns
  `(signs_passed, length_m, START_NAME, END_NAME)`.

### Extra: start-up road check
- **`find_invalid_signs(road_list)`**: loops over the starting `road` list and
  returns every `(index, sign)` that is not `"road"` and fails `is_valid_sign`.
  Before the program starts, the bad segments are listed and it stops:
  ```
  Error: the road list in road_simulation.py contains invalid signs:
    segment 14: 'buss'
    segment 17: 150
  Use 'road', 'bus', 'zebra' or a speed limit from 20 to 100 written as text, e.g. "80".
  ```

## Edge cases handled

| Situation | What happens |
| --- | --- |
| Menu input is text (`abc`), a decimal (`3.5`) or empty | Clear error with an example, asks again |
| Menu number out of range (`9`, `-1`) | Error naming the allowed range, asks again |
| Input closed with Ctrl+C / end of file | Message, then a clean exit (no traceback) |
| Sign typed as `car`, `19`, `101`, `-20`, `8.5` | "Not allowed" message, road unchanged |
| Insert/replace position outside the road, or `True`/`False` | Rejected, returns `False`, road unchanged |
| Speed limit stored as a number (`80`) instead of text (`"80"`) | Treated as invalid, listed at start-up |
| Starting road has a typo (`"buss"`) or an illegal limit (`"150"`) | Program lists each bad segment and stops (exit code 1) |
| Starting road is empty | Error with an example, stops (exit code 1) |
| Log file missing, a folder, unreadable, empty or not a transit log | `analyze_log.sh` prints a specific error, exit code 1 |
| Log written with Windows line endings (CRLF) | `analyze_log.sh` strips `\r` so the output stays clean |
| Log has sessions but no finished trip | Summary shows counts and says no trip was finished yet |

## Log analyser (`analyze_log.sh`)

Every run appends its events to `transit_session.log`. The script reads it and
prints a summary.

```bash
bash analyze_log.sh                      # uses transit_session.log
bash analyze_log.sh path/to/other.log    # or any log you pass in
```

- Uses the first argument as the log file, or `transit_session.log` by default.
- If the file does not exist, prints an error and exits with code `1`. It also
  stops with a specific message for a folder, an unreadable or empty file, a
  file with no simulation sessions, or more than one argument.
- Counts sessions (`===== New session started` lines), completed trips,
  zebra crossing stops and lane changes with `grep -c`.
- Shows the driver name and top speed of the **latest finished** trip with
  `grep | tail -n 1 | cut`.

Example output:

```
===== TRANSIT LOG SUMMARY =====
Log file            : transit_session.log
Sessions (runs)     : 1
Completed trips     : 1
Zebra crossing stops: 2
Lane changes        : 4
----- Latest trip -----
Driver              : Fadhiri
Top speed           : 80 km/h
```

## Testing

Each part was tested before committing:

- **Unit checks** for every function, including edge cases: `"19"`, `"101"`,
  `"-20"`, `"8.5"`, `""`, `80` (int), `None`; accelerating to just below and
  braking to just above the target; inserting at `0`, at `len`, at `-1` and past
  the end, or with `True`; replacing on an empty road; limits of `"150"` and `"5"`
  being ignored.
- **Start-up road check** with a road containing `"buss"` and `150`, and with an
  empty road: both stop with a clear message and exit code 1.
- **Full end-to-end run** with scripted input. It tested an invalid sign
  (`car`), bad menu input (`abc`, `99`), an insert at segment 15 and a replace
  at index 33, then drove the whole road. Trip report: 3500 m, 10 signs passed,
  231 s, top speed 80 km/h, 2 zebra stops, 4 lane changes. The web page showed
  the car changing lanes at the bus segments and stopping at both zebras.
- **`analyze_log.sh`** on the generated log (numbers match the trip report),
  and on a missing file, a folder, an empty file, a non-log file, a log with no
  finished trip and two arguments (each gives its own message).

## Note on the zebra wait time

The lab brief says the car stops for **5 seconds** at a zebra crossing, but the
provided starter code sets `ZEBRA_WAIT = 15`. I kept the starter value so the
provided files behave as given. To use the brief's value, change
`ZEBRA_WAIT = 15` to `ZEBRA_WAIT = 5` at the top of `road_simulation.py`.

## Author

Ndegeya Fadhiri ([@fadhiri-student](https://github.com/fadhiri-student))
