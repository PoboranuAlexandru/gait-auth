from flask import Flask, request, Response
import xgboost as xgb
import pandas as pd
import numpy as np
from datetime import datetime

# type of sensors
SENSORS = {"accelerometer", "heart_rate"}

# column names for Pandas dataframe
HEADERS = {
    "accelerometer": ["Timestamp", "Accelerometer_x", "Accelerometer_y", "Accelerometer_z"],
    "heart_rate": ["Timestamp", "Heart_rate"]
}

THRESHOLD_STD_ACCZ = 3.0
THRESHOLD_MEAN_ACCZ = 1.85
FACTOR_STD_ACCZ = 1.5

GOOD_THRESHOLD_STD_ACCZ = 1.3
GOOD_FACTOR_STD_ACCZ = 3.0

EXCEEDED_FACTOR_STD_ACCZ = 0.2
WINDOW = 10


app = Flask(__name__)
model = xgb.XGBClassifier()
model.load_model("XGBClassifier.json")


def procces_step(df, col_name_df):
    delta_time = (df['Timestamp'].iloc[-1] -
                  df['Timestamp'].iloc[0]).microseconds / 1000
    mean_std_final_step = np.asarray(
        df.drop(columns='Timestamp').agg(['mean', 'std']))

    final_step = np.empty(
        ((len(mean_std_final_step[0]) - 1) * 2,), dtype=mean_std_final_step[0].dtype)
    final_step[0::2] = mean_std_final_step[0][:-1]
    final_step[1::2] = mean_std_final_step[1][:-1]

    final_step_df = pd.DataFrame([final_step], columns=col_name_df)
    final_step_df["Heart_rate"] = mean_std_final_step[0][-1]
    final_step_df["Delta_Time"] = delta_time
    return final_step_df


def dateparse(x):
    return datetime.utcfromtimestamp(int(x)/1000).strftime('%Y-%m-%d %H:%M:%S.%f')


def preprocess(df):
    df['Timestamp'] = pd.to_datetime(df['Timestamp'].apply(dateparse))

    df.sort_values(by="Timestamp", inplace=True)
    df.reset_index(drop=True, inplace=True)

    df = split_sessions(df)
    df.reset_index(drop=True, inplace=True)
    df[('Accelerometer_x', 'std')] = df[('Accelerometer_x', 'std')].fillna(0)
    df[('Accelerometer_y', 'std')] = df[('Accelerometer_y', 'std')].fillna(0)
    df[('Accelerometer_z', 'std')] = df[('Accelerometer_z', 'std')].fillna(0)
    df.dropna(inplace=True)
    return df


def split_sessions(df):
    col_names = df.columns.values.tolist()
    col_names.remove('Timestamp')
    col_names.remove('Heart_rate')
    col_name_df = pd.MultiIndex.from_product([col_names, ['mean', 'std']])


    upper_limit = None
    lower_limit = None

    results = []

    mean_std = df['Accelerometer_z'].agg(['mean', 'std'])
    if mean_std['std'] > THRESHOLD_STD_ACCZ and mean_std['mean'] > THRESHOLD_MEAN_ACCZ:
        upper_limit = mean_std['mean'] + \
            EXCEEDED_FACTOR_STD_ACCZ * mean_std['std']
    elif mean_std['std'] < GOOD_THRESHOLD_STD_ACCZ:
        upper_limit = mean_std['mean'] + \
            GOOD_FACTOR_STD_ACCZ * mean_std['std']
    else:
        upper_limit = mean_std['mean'] + FACTOR_STD_ACCZ * mean_std['std']

    if mean_std['std'] < GOOD_THRESHOLD_STD_ACCZ:
        lower_limit = mean_std['mean'] - \
            GOOD_FACTOR_STD_ACCZ * mean_std['std']
    else:
        lower_limit = mean_std['mean'] - FACTOR_STD_ACCZ * mean_std['std']

    steps_df = df.loc[((df['Accelerometer_z'] < upper_limit) & (
        df['Accelerometer_z'] > lower_limit)) | (df['Accelerometer_z'].isnull())]

    max_steps = np.asarray(steps_df['Accelerometer_y'].groupby(
        np.arange(len(steps_df)) // WINDOW).idxmax())
    max_steps = np.append(max_steps, steps_df.iloc[-1].name)

    max_index = steps_df.first_valid_index()
    for max_i in max_steps:
        step_max_df = steps_df.loc[max_index:max_i]

        if len(step_max_df) < WINDOW // 2:
            if not step_max_df.empty:
                results.append(procces_step(step_max_df, col_name_df))
            max_index = max_i
            continue

        min_index = step_max_df['Accelerometer_y'].idxmin()

        results.append(procces_step(step_max_df.loc[max_index:min_index], col_name_df))
        results.append(procces_step(step_max_df.loc[min_index:max_i], col_name_df))

        max_index = max_i

    final_form_steps = pd.concat(results).interpolate(limit_direction='both')
    final_form_steps['Heart_rate'].interpolate(limit_direction='both', inplace=True)

    return final_form_steps


def get_dataframe(data):
    # compute the dataframe for each sensor
    dataframes = []
    for sensor in SENSORS:
        if data[sensor]:
            df = pd.DataFrame(data[sensor])
            df.columns = HEADERS[sensor]
            dataframes.append(df)

    # merge the dataframes
    dataframe = pd.concat(dataframes)
    return dataframe


def mostFrequency(np_results):
    # freq
    values, counts = np.unique(np_results, return_counts=True)
    # get the most predict label
    ind = np.argmax(counts)
    return values[ind]


@app.route("/", methods=["POST"])
def register_user():

    payload = request.get_json(silent=False)

    df = get_dataframe(payload['data'])
    data = preprocess(df)

    predicts = model.predict(data)
    pred = mostFrequency(predicts)

    print(f'Prediction {pred}', flush=True)
    if pred == payload["userId"]:
        return Response(status=200)
    return Response(status=403)


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
