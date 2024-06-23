import pandas as pd
import numpy as np
from math import radians, sin, cos, sqrt, asin
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

# Sample data
data = [
    (1, 'SOSP', 43831, 0.708333, 'Port A', 34.0522, -118.2437, '9434761', '6', None),
    (2, 'EOSP', 43831, 0.791667, 'Port A', 34.0522, -118.2437, '9434761', '6', None),
    (3, 'SOSP', 43832, 0.333333, 'Port B', 36.7783, -119.4179, '9434761', '6', None),
    (4, 'EOSP', 43832, 0.583333, 'Port B', 36.7783, -119.4179, '9434761', '6', None)
]

# Create DataFrame
columns = ['id', 'event', 'dateStamp', 'timeStamp', 'voyage_From', 'lat', 'lon', 'imo_num', 'voyage_Id', 'allocatedVoyageId']
df = pd.DataFrame(data, columns=columns)

# Define Haversine function to calculate distance
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in km
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) * 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) * 2
    c = 2 * asin(sqrt(a))
    return R * c * 0.539957  # Convert km to nautical miles

# Convert dateStamp and timeStamp to datetime
df['event_datetime'] = pd.to_datetime('1900-01-01') + pd.to_timedelta(df['dateStamp'], unit='D') + pd.to_timedelta(df['timeStamp'] * 24 * 60 * 60, unit='s')

# Calculate previous event details
df['prev_event'] = df.groupby('voyage_Id')['event'].shift(1)
df['prev_event_datetime'] = df.groupby('voyage_Id')['event_datetime'].shift(1)
df['prev_voyage_From'] = df.groupby('voyage_Id')['voyage_From'].shift(1)
df['prev_lat'] = df.groupby('voyage_Id')['lat'].shift(1)
df['prev_lon'] = df.groupby('voyage_Id')['lon'].shift(1)

# Calculate distance travelled
df['distance_travelled'] = df.apply(lambda row: haversine(row['prev_lat'], row['prev_lon'], row['lat'], row['lon']) if pd.notnull(row['prev_lat']) and pd.notnull(row['prev_lon']) else None, axis=1)

# Calculate time difference in minutes
df['time_difference'] = (df['event_datetime'] - df['prev_event_datetime']).dt.total_seconds() / 60

# Calculate sailing time and port stay duration
df['sailing_time'] = df.apply(lambda row: row['time_difference'] if row['event'] == 'SOSP' else None, axis=1)
df['port_stay_duration'] = df.apply(lambda row: row['time_difference'] if row['event'] == 'EOSP' else None, axis=1)

# Data visualization
fig, ax = plt.subplots(figsize=(12, 8))
ax.plot(df['event_datetime'], df['sailing_time'], label='Sailing Time', marker='o')
ax.plot(df['event_datetime'], df['port_stay_duration'], label='Port Stay Duration', marker='x')
ax.set_xlabel('Event DateTime')
ax.set_ylabel('Duration (minutes)')
ax.legend()
ax.grid(True)
plt.title('Voyage Timeline')
plt.show()

# Print the dataframe to validate the output
print(df)