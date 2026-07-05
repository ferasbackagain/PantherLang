# Capstone: Weather Data Processor

## Level
Intermediate

## Track
Data

## Prerequisites
- Academy Lessons 1-8
- Book Chapters 1-6

## Objective
Build a weather data processor that fetches data from an HTTP API, parses JSON, computes statistics, and prints a formatted report.

## Requirements
1. Use `http_get` to fetch weather-like data from httpbin.org
2. Use `json_decode` to parse the response into a structured object
3. Extract temperature values from the parsed data
4. Compute min, max, and average temperatures using `max()`, `min()`, math operators
5. Use `int()`, `float()`, `string()` for type conversion
6. Print a formatted weather report with statistics
7. Handle null response gracefully with a fallback

## Rubric
| Criteria | Points |
|----------|--------|
| Functionality | 40 |
| Data processing | 20 |
| Error handling | 20 |
| Documentation | 20 |

## Solution
Run: `python -m cli.panther_cli run docs/capstones/solutions/weather-processor.pan`

## Verification
Expected output (exact values may vary with network):
```
=== Weather Data Processor ===
[FETCH] Requesting weather data from httpbin.org...
[PARSE] Parsing JSON response...
Weather Report
  City: Sample City
  Conditions: partly cloudy
  Temperature: 22.5 C
  Humidity: 65%
  Wind: 12 km/h
Temperature Statistics:
  Readings: [18, 22, 25, 20, 19, 23, 21]
  Min: 18 C
  Max: 25 C
  Average: 21.1 C
=== Weather Processing Complete ===
```
