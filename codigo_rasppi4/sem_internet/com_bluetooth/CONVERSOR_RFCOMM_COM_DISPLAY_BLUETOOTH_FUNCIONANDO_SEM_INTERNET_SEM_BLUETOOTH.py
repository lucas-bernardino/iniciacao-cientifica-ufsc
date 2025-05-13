import time
import threading
import serial
import binascii
import RPi.GPIO as GPIO
import datetime
import requests
import subprocess
import multiprocessing
import math
import bluetooth
from smbus2 import SMBus
from handle_sensors_module import *

from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306
from time import sleep
from PIL import ImageFont

import board
import busio
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

import random
import math

sensor_gps = serial.Serial("/dev/serial0", 115200, timeout=1)
sensor_angulo = SMBus(1)
display_connection = i2c(port=1, address=0x3C)
display = ssd1306(display_connection)
sensor_bluetooth = serial.Serial(
    port='/dev/rfcomm0',
    baudrate=9600,
    timeout=1,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE
)


# Conversor setup
busio_i2c = busio.I2C(board.SCL, board.SDA)

ads_i2c = ADS.ADS1115(busio_i2c)
ads_i2c.gain = 1

sensor_pressao_freio = AnalogIn(ads_i2c, ADS.P0)
#

# Conversor setup


# Configuration to increase the frequency of the GPS Sensor.
# Before every command, it's necessary to send this command.
unlock = bytes.fromhex('FF AA 69 88 B5')
# After every command, it's necessary to send this command.
save = bytes.fromhex('FF AA 00 00 00')

sensor_gps.write(unlock)
time.sleep(0.1)

rrate = bytes.fromhex('FF AA 03 0B 00')  # Setting the rate to 100Hz.
sensor_gps.write(rrate)
time.sleep(0.1)

baud = bytes.fromhex('FF AA 04 06 00')  # Setting the baud rate to 115200.
sensor_gps.write(baud)
time.sleep(0.1)

sensor_gps.write(save)
time.sleep(0.1)

# Flags and variables declarations.
contador = 0
interrupt_flag = True
check_bug = True
dados_package = {}
contador_botao = 0
flag_button_collection = False
data_sensors = ""

# Every time the button is pressed, this function is called.
# It toggles the flag so that no more data is received until the button is pressed again.


def button_pressed_callback(channel):
    global interrupt_flag, data_sensors, contador_botao, flag_button_collection
    interrupt_flag = not interrupt_flag
    print("Button pressed")
    current_time = datetime.datetime.now()
    print(current_time)
    print(f"Contador: {contador}")
    data_sensors = ""


# Button setup
BUTTON_GPIO = 26
GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.add_event_detect(BUTTON_GPIO, GPIO.FALLING,
                      callback=button_pressed_callback, bouncetime=1000)


# The tick_ms and calculate_elapse functions are auxiliary functions for the RPM and Speed calculations.
def ticks_ms():
    return int(time.time() * 1000)


def calculate_elapse(channel):
    global pulse, start_timer, elapse
    pulse += 1
    elapse = ticks_ms() - start_timer
    start_timer = ticks_ms()


# These variables can be called with the calculate_speed functions. They will be updated in that function.
dist_meas = 0.00
km_per_hour = 0
rpm = 0
elapse = 0
pulse = 0
start_timer = ticks_ms()

# Hall sensor, that is located on the wheel, setup.
HALL_PIN = 21
GPIO.setmode(GPIO.BCM)
sensor = GPIO.setup(HALL_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.add_event_detect(HALL_PIN, GPIO.FALLING, callback=calculate_elapse)

# This functions changes the variables declared above. The parameter is the wheel radius, which was about 32 cm.


def calculate_speed(r_cm):
    global pulse, elapse, rpm, dist_km, dist_meas, km_per_hour
    if elapse != 0:
        rpm = 1 / (elapse / 60000)
        circ_cm = 2 * math.pi * r_cm
        dist_km = circ_cm / 100000
        km_per_sec = dist_km / (elapse / 1000)
        km_per_hour = km_per_sec * 3600
        dist_meas = (dist_km * pulse) * 1000
        return km_per_hour


# This function was needed since sometimes the GPS Sensor wasn't sending data.
# It basically restarts the data acquisition and the flag is controlled on the thread functions.
def check_bug_timer():
    global interrupt_flag, check_bug
    if check_bug:
        interrupt_flag = False
        time.sleep(0.5)
        interrupt_flag = True


# Connect bluetooth

###########
bluetooth_buffer = "!{}@{}*{}".format(0.0, 0.0, 0.0)
# bluetooth_lock = threading.Lock()
#
#
# def bluetooth_thread():
#     global bluetooth_buffer
#     while True:
#         try:
#             bluetooth_data = sensor_bluetooth.readline()
#             if bluetooth_data:
#                 bluetooth_data = bluetooth_data.decode().rstrip().split(',')
#                 bluetooth_buffer = "!{}@{}*{}".format(bluetooth_data[0].strip(
#                 ), bluetooth_data[1].strip(), bluetooth_data[2].strip())
#         except Exception as e:
#             print("Deu excecao na thread bluetooth: ", e)
#
###########
# This is the piece of code responsible for receiving the GPS Sensor data.

###
# Sensor de pressao


pressao_buffer = ""


def sensor_pressao_thread():
    global pressao_buffer
    while True:
        try:
            current_voltage = sensor_pressao_freio.voltage
            # Calibrar os fatores com regressao linear
            # pressao = current_voltage * A + B
            pressao_buffer = ""
            pressao_buffer = f"~{current_voltage:.4f}"
        except Exception as e:
            print("Deu problema na thread sensor pressao: ", e)
            continue

# Sensor de pressao
###


raw_data_lock = threading.Lock()
display_shared_buff = ()


def gps_thread():
    global run_core_1
    global data_sensors
    global cont
    global check_bug

    # First, read the sensor output. If it's "5551", it means that a new package containing data can be saved.
    # The GPS Sensor can output information such as acceleration, angular speed, latitude/longitude and more. Check the datasheet for more.
    # Every new sensor within the GPS Sensor starts its data with "55XX", where XX can be a number between 51 and 58, depending what's
    # the output of the sensor, where acceleration is 51, angular speed is 52 and so on. This is why it's read and saved 86 bytes,
    # because it contains the whole chunk of data captured by the sensor at that instant.
    while interrupt_flag:
        read_gps = sensor_gps.read(2)
        if read_gps:
            if binascii.hexlify(read_gps).decode('utf-8') == "5551":
                check_bug = False
                if not interrupt_flag:
                    data_sensors = ""
                    read_gps = ""
                    break

                data_worthy = "5551" + \
                    binascii.hexlify(sensor_gps.read(86)).decode('utf-8')

                data_sensors = ""
                data_sensors += data_worthy

    data_worthy = ""
    data_sensors = ""


# This is the piece of code responsible for receiving the angle data sent by the AS5600.
def angle_thread():
    global run_core_1
    global data_sensors
    global contador
    global dados_package
    global bluetooth_buffer
    global display_shared_buff

    angle_degrees = "111.11"

    while interrupt_flag:
        try:
            # According to the datasheet, the raw angle is obtained by reading from two registers.
            # The sensor has a 12-bit resolution.

            # The register whose address is 0x0C contains the high byte (11:8)
            high_byte = sensor_angulo.read_byte_data(0x36, 0x0C)

            # The register whose address is 0x0D contains teh low byte (7:0)
            low_byte = sensor_angulo.read_byte_data(0x36, 0x0D)

            # Since it's a 12-bit sensor, it's first necessary to shift the high byte by 8 bits and sum it with the low byte.
            # This will result in a 16 bit data, so it's perfomed a AND operation to get only the 12 bits.
            # The value 0.08789 comes from dividing 360 by 4096 (2^12)
            high_byte = high_byte << 8
            raw_angle = high_byte + low_byte
            angle_degrees = (raw_angle & 0xFFF) * 0.08789
            angle_degrees = "{:.2f}".format(angle_degrees)

        except OSError:
            print(
                "Modulo de estercamento com problemas... Salvando 111.11 como valor padrao")
            angle_degrees = "111.11"

        finally:
            if len(data_sensors) == 176:

                if not interrupt_flag:
                    data_sensors = ""
                    angle_degrees = ""
                    break

                data_sensors += (str(datetime.datetime.now())).split()[1]

                data_sensors += angle_degrees

                if len(data_sensors) > 20:
                    calculate_speed(32)
                    hall_data = "#{:.2f}${:.2f}".format(rpm, km_per_hour)
                    data_sensors += hall_data
                    data_sensors += bluetooth_buffer
                    data_sensors += pressao_buffer
                    arquivo.write(data_sensors + "\n")

                    print("Dados: ", data_sensors)

                    contador += 1

                    with raw_data_lock:
                        display_shared_buff = (
                            data_sensors[132:154], km_per_hour)

                data_sensors = ""

    angle_degrees = ""
    data_sensors = ""


def show_data_display():
    big_font = ImageFont.truetype(
        "/usr/local/share/fonts/MononokiNerdFont-Bold.ttf", 22)
    small_font = ImageFont.truetype(
        "/usr/local/share/fonts/MononokiNerdFont-Bold.ttf", 15)
    while True:
        try:
            sleep(0.1)
            with canvas(display) as draw:
                with raw_data_lock:
                    velocidade_gps = display_shared_buff[0]
                    velocidade_gps = handleSensor7(velocidade_gps)

                    velocidade_hall = display_shared_buff[1]
                    current_time = (
                        str(datetime.datetime.now())).split()[1][:8]
                    draw.text(
                        (15, 0), "GPS", fill="green", font=small_font)
                    draw.text(
                        (0, 20), f"{velocidade_gps:.2f}", fill="green", font=big_font)
                    draw.text(
                        (82, 0), "HALL", fill="blue", font=small_font)
                    draw.text(
                        (70, 20), f"{velocidade_hall:.2f}", fill="blue", font=big_font)
                    draw.text((28, 48), f"{current_time}",
                              fill="blue", font=small_font)
        except Exception as e:
            print("Problemas com o display...")


# This infinite loop is responsible for dealing with what happens after the button is pressed
while True:
    if interrupt_flag:
        print("entrei na interrupcao")
        data_sensors = ""

        sensor_gps.flushInput()
        sensor_gps.flushOutput()

        try:
            # The number.txt is the file responsible for keeping track of how what should the name of the file be when saving the data
            read_number = open('number.txt', 'r')
            last_number = int(read_number.read())
            # The data is saved in dadosN.txt, where N is the number tracked by the number.txt file.
            arquivo = open(f"dados{str(last_number + 1)}.txt", "a")
            write_number = open('number.txt', 'w')
            write_number.write(str(last_number + 1))
            read_number.close()
            write_number.close()
        except Exception as e:
            print("ERRO LINHA 29: ", e)
            arquivo = open("dados0.txt", "a")
            write_number = open('number.txt', 'a')
            write_number.write('0')
            write_number.close()
            pass

        # In the next lines the threads are started.

        timer_thread = threading.Timer(1.5, check_bug_timer)
        check_bug = True
        timer_thread.start()

        thread1 = threading.Thread(target=angle_thread)
        thread1.start()
        #########
        # thread2 = threading.Thread(target=bluetooth_thread)
        # thread2.start()
        # #########
        thread_display = threading.Thread(target=show_data_display)
        thread_display.start()

        thread_pressao = threading.Thread(target=sensor_pressao_thread)
        thread_pressao.start()

        gps_thread()

        data_sensors = ""
        print("apos as threads")

        sensor_gps.flushInput()
        sensor_gps.flushOutput()

        arquivo.close()
