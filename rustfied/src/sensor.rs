use std::fmt::Write as _;
use std::io::Write;
use std::{
    fmt,
    sync::{Arc, Mutex},
};

use chrono::prelude::*;
use serde_json::json;

use crate::utils::{clean_accel, clean_angle, clean_vel};

pub struct BikeSensor {
    pub uart: Arc<Mutex<UartSensor>>,
    pub i2c: Arc<Mutex<I2CSensor>>,
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
    pub fn new(file_name: &str) -> BikeSensor {
        BikeSensor {
            uart: Arc::new(Mutex::new(UartSensor::new())),
            i2c: Arc::new(Mutex::new(I2CSensor::new())),
            file: Arc::new(Mutex::new(
                std::fs::File::create(file_name)
                    .expect("Failed to create file with path the given path"),
            )),
            counter: Arc::new(Mutex::new(0)),
        }
    }

    pub fn update(&mut self) -> Result<(), Box<dyn std::error::Error + '_>> {
        self.uart.lock()?.update()?;
        self.i2c.lock()?.update()?;

        Ok(())
    }

    pub fn write_file(&self) -> Result<(), Box<dyn std::error::Error + '_>> {
        let mut uart = self.uart.lock()?;
        let mut i2c = self.i2c.lock()?;

        if uart.is_ready && i2c.is_ready {
            let uart_str = uart.buffer.iter().fold(String::new(), |mut output, b| {
                let _ = write!(output, "{b:02x}");
                output
            });

            self.file
                .lock()?
                .write_all(format!("{}{}\n", uart_str, i2c.steer).as_bytes())?;

            uart.is_ready = false;
            i2c.is_ready = false;
        }
        Ok(())
    }

    pub fn get_json(&self) -> Result<serde_json::Value, Box<dyn std::error::Error + '_>> {
        let uart = self.uart.lock()?;
        let i2c = self.i2c.lock()?;

        let mut counter = self.counter.lock()?;

        //'18:25:52.843023'
        let time: DateTime<Local> = Local::now();
        let time_str = format!("{}:{}:{}", time.hour(), time.minute(), time.second());

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
            "rot": 0.0,
            "veloc": 0.0,
            "long": 0.0,
            "lat": 0.0,
            "press_ar": 0.0,
            "altitude": 0.0,
            "termopar1": 0.0,
            "termopar2": 0.0,
            "termopar3": 0.0,
            "Horario" : time_str
        });

        *counter += 1;
        Ok(json)
    }
}

pub struct UartSensor {
    pub buffer: Vec<u8>,

    pub acceleration: [f32; 3],
    pub angle_velocity: [f32; 3],
    pub angle: [f32; 3],

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
            is_ready: true,
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str> {
        let accel_raw = &self.buffer[0..11];
        let angle_vel_raw = &self.buffer[11..22];
        let angle_raw = &self.buffer[22..33];

        self.acceleration = clean_accel(accel_raw)?;
        self.angle_velocity = clean_vel(angle_vel_raw)?;
        self.angle = clean_angle(angle_raw)?;

        Ok(())
    }
}

pub struct I2CSensor {
    pub buffer: Vec<u8>,
    pub steer: f32,

    pub is_ready: bool,
}

impl fmt::Display for I2CSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Steer: {}", self.steer)
    }
}

impl I2CSensor {
    pub fn new() -> I2CSensor {
        let buffer: Vec<u8> = vec![0; 3];
        let steer: f32 = 1.0;

        I2CSensor {
            buffer,
            steer,
            is_ready: true,
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str> {
        self.steer += 1.0;

        Ok(())
    }
}

