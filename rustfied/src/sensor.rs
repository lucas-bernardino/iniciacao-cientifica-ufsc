use std::{fmt, sync::{Arc, Mutex}};


use crate::utils::{clean_accel, clean_vel, clean_angle};

pub struct BikeSensor {
    pub uart: Arc<Mutex<UartSensor>>,
    pub i2c: Arc<Mutex<I2CSensor>>
}

impl fmt::Display for BikeSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Uart -> {}\nI2C -> {}", self.uart.lock().unwrap(), self.i2c.lock().unwrap())
    }
}

impl BikeSensor {
    pub fn new() -> Self {
        BikeSensor {
            uart: Arc::new(Mutex::new(UartSensor::new())),
            i2c: Arc::new(Mutex::new(I2CSensor::new()))
        }   
    }

    pub fn update(&mut self) -> Result<(), Box<dyn std::error::Error + '_>>{
        self.uart.lock()?.update()?;
        self.i2c.lock()?.update()?;

        Ok(())
    }
}

pub struct UartSensor {
    pub buffer: Vec<u8>,

    pub acceleration: [f32; 3],
    pub angle_velocity: [f32; 3],
    pub angle: [f32; 3],

    pub is_ready: bool
}

impl fmt::Display for UartSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Acceleration: [{}, {}, {}]\nAngle Velocity: [{}, {}, {}]\nAngle: [{}, {}, {}]\n",
                   self.acceleration[0], self.acceleration[1], self.acceleration[2],
                   self.angle_velocity[0], self.angle_velocity[1], self.angle_velocity[2],
                   self.angle[0], self.angle[1], self.angle[2])
    }
}

impl UartSensor {
    pub fn new() -> Self {
        let mut buff: Vec<u8> = vec![0; 42];
        buff.insert(0, 0x55);
        buff.insert(1, 0x51);
        
        UartSensor {
            buffer: buff,
            acceleration: [0.0; 3],
            angle_velocity: [0.0; 3],
            angle: [0.0; 3],
            is_ready: true
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str>{
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

    pub is_ready: bool
}

impl fmt::Display for I2CSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Steer: {}", self.steer)
    }
}

impl I2CSensor {
    pub fn new() -> Self {
        let buffer: Vec<u8> = vec![0; 3];
        let steer: f32 = 1.0;

        I2CSensor {
            buffer,
            steer,
            is_ready: true
        }
    }

    pub fn update(&mut self) -> Result<(), &'static str>{
        self.steer += 1.0;

        Ok(())
    }
}