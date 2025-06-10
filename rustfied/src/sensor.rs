use std::fmt::Write as _;
use std::io::{Read, Write};
use std::{
    fmt,
    str::FromStr,
    sync::{Arc, Mutex},
};

use ads1x1x::ic::{Ads1115, Resolution16Bit};
use ads1x1x::{Ads1x1x, TargetAddr};
use chrono::prelude::*;
use linux_embedded_hal::I2cdev;
use serde_json::json;

use i2cdev::core::*;
use i2cdev::linux::LinuxI2CDevice;

use crate::utils::{clean_accel, clean_angle, clean_gps_vel, clean_vel};

use rppal::gpio::Gpio;

pub struct BikeSensor {
    pub uart: Arc<Mutex<UartSensor>>,
    pub i2c: Arc<Mutex<I2CSensor>>,
    pub bluetooth: Arc<Mutex<BluetoothSensor>>,
    pub hall: Arc<Mutex<HallSensor>>,
    pub brake_pressure: Arc<Mutex<BrakePressureSensor>>,
    pub file: Arc<Mutex<std::fs::File>>,

    pub counter: Arc<Mutex<i32>>,
}

impl fmt::Display for BikeSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Uart -> {}\nI2C -> {}",
            self.uart.lock().unwrap(),
            self.i2c.lock().unwrap()
        )
    }
}

impl BikeSensor {
    pub fn new() -> BikeSensor {
        let time: DateTime<Local> = Local::now();
        let file_name = format!("{}-{}-{}.txt", time.hour(), time.minute(), time.second(),);

        BikeSensor {
            uart: Arc::new(Mutex::new(UartSensor::new())),
            i2c: Arc::new(Mutex::new(I2CSensor::new())),
            bluetooth: Arc::new(Mutex::new(BluetoothSensor::new())),
            hall: Arc::new(Mutex::new(HallSensor::new())),
            brake_pressure: Arc::new(Mutex::new(BrakePressureSensor::new())),
            file: Arc::new(Mutex::new(
                std::fs::File::create(file_name)
                    .expect("Failed to create file with path the given path"),
            )),
            counter: Arc::new(Mutex::new(0)),
        }
    }

    pub fn update_file(&mut self) -> Result<(), Box<dyn std::error::Error + '_>> {
        let time: DateTime<Local> = Local::now();
        let file_name = format!("{}-{}-{}.txt", time.hour(), time.minute(), time.second(),);

        self.file = Arc::new(Mutex::new(std::fs::File::create(file_name)?));

        Ok(())
    }

    pub fn write_file(&self) -> Result<(), Box<dyn std::error::Error + '_>> {
        let mut uart = self.uart.lock()?;
        let mut i2c = self.i2c.lock()?;
        let bluetooth = self.bluetooth.lock()?;
        let mut hall = self.hall.lock()?;
        let brake_press = self.brake_pressure.lock()?;

        if uart.is_ready && i2c.is_ready {
            let uart_str = uart.buffer.iter().fold(String::new(), |mut output, b| {
                let _ = write!(output, "{b:02x}");
                output
            });

            let time: DateTime<Local> = Local::now();
            let time_str = format!(
                "{}:{}:{:02}.{}",
                time.hour(),
                time.minute(),
                time.second(),
                time.nanosecond().to_string()[..6].parse::<u32>().unwrap()
            );

            hall.calculate_speed();

            let hall_speed = hall.km_per_hour;
            let mut hall_rpm = 60000.0 / hall.elapse.as_millis() as f32;
            if hall_rpm.is_infinite() {
                hall_rpm = 0.0;
            }
            self.file.lock()?.write_all(
                format!(
                    "{}{}{}#{:.2}${:.2}!{:.2}@~{}\n",
                    uart_str,
                    time_str,
                    i2c.steer,
                    hall_speed,
                    hall_rpm,
                    bluetooth.termocouple1,
                    brake_press.brake_pressure
                )
                .as_bytes(),
            )?;

            uart.is_ready = false;
            i2c.is_ready = false;
        }
        Ok(())
    }

    pub fn get_json(&self) -> Result<serde_json::Value, Box<dyn std::error::Error + '_>> {
        let uart = self.uart.lock()?;
        let i2c = self.i2c.lock()?;
        let bluetooth = self.bluetooth.lock()?;
        let mut hall = self.hall.lock()?;

        let mut counter = self.counter.lock()?;

        //'18:25:52.843023'
        let time: DateTime<Local> = Local::now();
        let time_str = format!("{}:{}:{}", time.hour(), time.minute(), time.second(),);

        hall.calculate_speed();
        let hall_speed = hall.km_per_hour;
        let mut hall_rpm = 60000.0 / hall.elapse.as_millis() as f32;
        if hall_rpm.is_infinite() {
            hall_rpm = 0.0;
        }

        let json = json!({
            "id": *counter,
            "acel_x": uart.acceleration[0],
            "acel_y": uart.acceleration[1],
            "acel_z": uart.acceleration[2],
            "vel_x": uart.angle_velocity[0],
            "vel_y": uart.angle_velocity[1],
            "vel_z": uart.angle_velocity[2],
            "roll": uart.angle[0],
            "pitch": uart.angle[0],
            "yaw": uart.angle[0],
            "mag_x": 0.0,
            "mag_y": 0.0,
            "mag_z": 0.0,
            "temp": 0.0,
            "esterc": i2c.steer,
            "rot": format!("{:.2}", hall_rpm),
            "veloc": 0.0,
            "long": 0.0,
            "lat": 0.0,
            "press_ar": format!("{:.2}", hall_speed),
            "altitude": 0.0,
            "termopar1": bluetooth.termocouple1,
            "Horario" : time_str
        });

        *counter += 1;
        Ok(json)
    }

    pub fn get_display_data(&self) -> Result<[f32; 2], Box<dyn std::error::Error + '_>> {
        let uart = self.uart.lock()?;
        let mut hall = self.hall.lock()?;
        hall.calculate_speed();

        Ok([uart.gps_vel, hall.km_per_hour])
    }
}

pub struct UartSensor {
    pub buffer: Vec<u8>,

    pub acceleration: [f32; 3],
    pub angle_velocity: [f32; 3],
    pub angle: [f32; 3],

    pub gps_vel: f32,

    pub is_ready: bool,
}

impl fmt::Display for UartSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Acceleration: [{}, {}, {}]\nAngle Velocity: [{}, {}, {}]\nAngle: [{}, {}, {}]\n",
            self.acceleration[0],
            self.acceleration[1],
            self.acceleration[2],
            self.angle_velocity[0],
            self.angle_velocity[1],
            self.angle_velocity[2],
            self.angle[0],
            self.angle[1],
            self.angle[2]
        )
    }
}

impl UartSensor {
    pub fn new() -> UartSensor {
        let mut buff: Vec<u8> = vec![0; 86];
        buff.insert(0, 0x55);
        buff.insert(1, 0x51);

        UartSensor {
            buffer: buff,
            acceleration: [0.0; 3],
            angle_velocity: [0.0; 3],
            angle: [0.0; 3],
            gps_vel: 0.0,
            is_ready: true,
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str> {
        let accel_raw = &self.buffer[0..11];
        let angle_vel_raw = &self.buffer[11..22];
        let angle_raw = &self.buffer[22..33];
        let gps_vel_raw = &self.buffer[66..77];

        self.acceleration = clean_accel(accel_raw)?;
        self.angle_velocity = clean_vel(angle_vel_raw)?;
        self.angle = clean_angle(angle_raw)?;
        self.gps_vel = clean_gps_vel(gps_vel_raw)?;

        Ok(())
    }
}

pub struct I2CSensor {
    i2c_device: LinuxI2CDevice,
    pub steer: String,
    pub is_ready: bool,
}

impl fmt::Display for I2CSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Steer: {}", self.steer)
    }
}

impl I2CSensor {
    pub fn new() -> I2CSensor {
        let steer = String::from("1.0");
        let i2c_device = LinuxI2CDevice::new("/dev/i2c-1", 0x36).expect("Failed to connect to I2C");
        I2CSensor {
            i2c_device,
            steer,
            is_ready: true,
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str> {
        let high_byte = (self
            .i2c_device
            .smbus_read_byte_data(0x0C)
            .expect("Failed to read register 0x0C") as u16)
            << 8;
        let low_byte = self
            .i2c_device
            .smbus_read_byte_data(0x0D)
            .expect("Failed to read register 0x0D") as u16;

        let raw_angle = high_byte | low_byte;
        let angle_degrees = ((raw_angle & 0xFFF) as f64) * 0.08789;

        self.steer = format!("{:.2}", angle_degrees);
        Ok(())
    }
}

pub struct BluetoothSensor {
    //bluetooth_conn: BtSocket,
    cs_pin: rppal::gpio::OutputPin,
    clk_pin: rppal::gpio::OutputPin,
    data_pin: rppal::gpio::InputPin,
    pub termocouple1: f32,
}

impl BluetoothSensor {
    pub fn new() -> BluetoothSensor {
        let mut cs_pin = Gpio::new().unwrap().get(27).unwrap().into_output();
        let clk_pin = Gpio::new().unwrap().get(17).unwrap().into_output();
        let data_pin = Gpio::new().unwrap().get(22).unwrap().into_input();

        cs_pin.set_high();

        BluetoothSensor {
            cs_pin,
            clk_pin,
            data_pin,

            termocouple1: 0.0,
        }
    }

    fn read_max6675(&mut self) -> f32 {
        self.cs_pin.set_low();

        let mut bytesin: u16 = 0;
        for i in 0..16 {
            self.clk_pin.set_low();
            std::thread::sleep(std::time::Duration::from_micros(100));

            bytesin <<= 1;
            let bit = self.data_pin.is_high();
            if bit {
                bytesin |= 1;
            }

            self.clk_pin.set_high();
            std::thread::sleep(std::time::Duration::from_micros(100));
        }

        std::thread::sleep(std::time::Duration::from_millis(1));
        self.cs_pin.set_high();

        let data_16 = (bytesin >> 3) & 0xFFF;
        let temp = (data_16 as f32) * 0.25;
        temp as f32
    }

    pub fn update(&mut self) {
        self.termocouple1 = self.read_max6675();
    }
}

#[derive(Debug, Clone)]
pub struct HallSensor {
    wheel_radius: f32,
    pub elapse: std::time::Duration,
    last_time: std::time::Instant,
    pub km_per_hour: f32,
}

impl HallSensor {
    pub fn new() -> Self {
        Self {
            wheel_radius: 32.0,
            elapse: std::time::Duration::ZERO,
            last_time: std::time::Instant::now(),
            km_per_hour: 0.0,
        }
    }

    pub fn update(&mut self) {
        let now = std::time::Instant::now();
        self.elapse = now.duration_since(self.last_time);
        self.last_time = now;
    }

    pub fn calculate_speed(&mut self) {
        if self.elapse.as_millis() > 0 {
            let rpm = 60000.0 / self.elapse.as_millis() as f32;
            let circ_cm = 2.0 * std::f32::consts::PI * self.wheel_radius;
            let dist_km = circ_cm / 100000.0;
            let km_per_sec = dist_km / (self.elapse.as_millis() as f32 / 1000.0);
            self.km_per_hour = km_per_sec * 3600.0;
        }
    }
}

pub struct BrakePressureSensor {
    pub adc: Ads1x1x<I2cdev, Ads1115, Resolution16Bit, ads1x1x::mode::OneShot>,
    pub brake_pressure: f32,
}

impl BrakePressureSensor {
    pub fn new() -> Self {
        let i2c_dev = I2cdev::new("/dev/i2c-1").unwrap();
        let mut adc = Ads1x1x::new_ads1115(i2c_dev, TargetAddr::default());
        adc.set_full_scale_range(ads1x1x::FullScaleRange::Within4_096V)
            .unwrap();

        Self {
            adc,
            brake_pressure: 0.0,
        }
    }

    pub fn update(&mut self) {
        let reading = self.adc.read(ads1x1x::channel::SingleA0);
        if reading.is_ok() {
            let voltage_val =
                (reading.unwrap() as f32) * 4.096 / ((i32::pow(2, 16 - 1) - 1) as f32);
            self.brake_pressure = voltage_val;
        }
    }
}
