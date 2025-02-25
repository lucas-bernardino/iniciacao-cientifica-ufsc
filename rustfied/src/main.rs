use std::time::Duration;

use rustfied::sensor::BikeSensor;

fn main() {

    let port_name = "/dev/ttyUSB0";
    let baud_rate = 9600;


    let port = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_secs(10))
        .open();

    match port {
        Ok(mut port) => {
            let mut buff_check: Vec<u8> = vec![0; 2];
            let mut sensor = BikeSensor::new();
            loop {
                port.read_exact(&mut buff_check).expect("Failed to read to buff_check");
                if buff_check.starts_with(&[0x55, 0x51]) {
                    port.read_exact(&mut sensor.buffer[2..]).expect("Failed to read from buff");

                    sensor.update();
                    println!("{sensor}");
                } 
            }
        }
        Err(e) => {
            eprintln!("Failed to open \"{}\". Error: {}", port_name, e);
            ::std::process::exit(1);
        }
    }
}
