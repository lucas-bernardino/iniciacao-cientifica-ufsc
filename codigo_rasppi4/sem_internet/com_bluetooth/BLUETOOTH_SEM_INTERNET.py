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


sensor_gps = serial.Serial("/dev/serial0", 115200, timeout=1)
sensor_angulo = SMBus(1)

#Configuration to increase the frequency of the GPS Sensor.
unlock = bytes.fromhex('FF AA 69 88 B5') # Before every command, it's necessary to send this command.
save = bytes.fromhex('FF AA 00 00 00') # After every command, it's necessary to send this command.

sensor_gps.write(unlock)
time.sleep(0.1)

rrate = bytes.fromhex('FF AA 03 0B 00') # Setting the rate to 100Hz.
sensor_gps.write(rrate)
time.sleep(0.1)

baud = bytes.fromhex('FF AA 04 06 00') # Setting the baud rate to 115200.
sensor_gps.write(baud)
time.sleep(0.1)

sensor_gps.write(save)
time.sleep(0.1)

#Flags and variables declarations.
contador = 0
interrupt_flag = False
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
GPIO.add_event_detect(BUTTON_GPIO, GPIO.FALLING, callback=button_pressed_callback, bouncetime=1000)


# The tick_ms and calculate_elapse functions are auxiliary functions for the RPM and Speed calculations.
def ticks_ms():
    return int(time.time() * 1000)

def calculate_elapse(channel):
    global pulse, start_timer, elapse
    pulse += 1
    elapse = ticks_ms() - start_timer
    start_timer = ticks_ms()

#These variables can be called with the calculate_speed functions. They will be updated in that function.
dist_meas = 0.00
km_per_hour = 0
rpm = 0
elapse = 0
pulse = 0
start_timer = ticks_ms()

# Hall sensor, that is located on the wheel, setup.
HALL_PIN = 23
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
port = 1
target_address = "98:DA:50:02:E3:9E"

# Create a Bluetooth socket
sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
sock.connect((target_address, port))

bluetooth_buffer = ""
bluetooth_lock = threading.Lock()

def bluetooth_thread():
    global bluetooth_buffer
    while True:
        bluetooth_data = str(sock.recv(1024)).replace("b", "").replace(r"'", "").replace(r"\r\n", "").split(',')
        bluetooth_buffer = "!{}@{}*{}".format(bluetooth_data[0].strip(), bluetooth_data[1].strip(), bluetooth_data[2].strip())


# This is the piece of code responsible for receiving the GPS Sensor data.
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
            if binascii.hexlify(read_gps).decode('utf-8') == "5551" :
                    check_bug = False
                    if not interrupt_flag:
                        data_sensors = ""
                        read_gps = ""
                        break

                    data_worthy = "5551" + binascii.hexlify(sensor_gps.read(86)).decode('utf-8')

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
            print("Modulo de estercamento com problemas... Salvando 111.11 como valor padrao")
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
                    arquivo.write(data_sensors + "\n")

                    print("Dados: ", data_sensors)

                    contador +=1

                data_sensors = ""

    angle_degrees = ""
    data_sensors = ""

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
        thread2 = threading.Thread(target=bluetooth_thread)
        thread2.start()

        gps_thread()

        data_sensors = ""
        print("apos as threads")

        sensor_gps.flushInput()
        sensor_gps.flushOutput()

        arquivo.close()
