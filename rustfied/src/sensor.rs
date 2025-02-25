use std::fmt;

use crate::utils::{clean_accel, clean_vel, clean_angle};

pub struct BikeSensor {
    pub buffer: Vec<u8>,

    pub acceleration: [f32; 3],
    pub angle_velocity: [f32; 3],
    pub angle: [f32; 3],
}

impl fmt::Display for BikeSensor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Acceleration: [{}, {}, {}]\nAngle Velocity: [{}, {}, {}]\nAngle: [{}, {}, {}]\n",
                   self.acceleration[0], self.acceleration[1], self.acceleration[2],
                   self.angle_velocity[0], self.angle_velocity[1], self.angle_velocity[2],
                   self.angle[0], self.angle[1], self.angle[2])
    }
}

impl BikeSensor {
    pub fn new() -> Self {
        let mut buff: Vec<u8> = vec![0; 42];
        buff.insert(0, 0x55);
        buff.insert(1, 0x51);
        
        BikeSensor {
            buffer: buff,
            acceleration: [0.0; 3],
            angle_velocity: [0.0; 3],
            angle: [0.0; 3]
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
