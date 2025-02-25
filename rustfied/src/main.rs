use std::{sync::{Arc, Mutex}, time::Duration};

use rustfied::sensor::{BikeSensor, UartSensor, I2CSensor};

#[tokio::main]
async fn main() {
    let sensor = BikeSensor::new();

    let uart_sensor = Arc::clone(&sensor.uart);
    let i2c_sensor = Arc::clone(&sensor.i2c);

    let uart =tokio::spawn(async move {
        uart_sensor_task(uart_sensor).await;
    });

    let i2c = tokio::spawn(async move {
        i2c_sensor_task(i2c_sensor).await;
    }); 

    let _ = tokio::join!(uart, i2c);

}

async fn uart_sensor_task(uart_sensor: Arc<Mutex<UartSensor>>) {
    let port_name = "/dev/ttyUSB0";
    let baud_rate = 9600;

    let port = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_secs(10))
        .open();

    match port {
        Ok(mut port) => {
            let mut buff_check: Vec<u8> = vec![0; 2];
            loop {
                port.read_exact(&mut buff_check).expect(" --- IMPROVE ERROR HANDLING --- ");
                if buff_check.starts_with(&[0x55, 0x51]) {
                    port.read_exact(&mut uart_sensor.lock().unwrap().buffer[2..]).expect(" --- IMPROVE ERROR HANDLING --- ");

                    let _ = uart_sensor.lock().unwrap().update().inspect_err(|e| eprintln!("Failed to update sensor. Error: {e}")); // Still need to improve error handling
                    println!("{}", uart_sensor.lock().unwrap());
                } 
            }
        }
        Err(e) => {
            eprintln!("Failed to open \"{}\". Error: {}", port_name, e);
            ::std::process::exit(1);
        }
    } 
}

async fn i2c_sensor_task(i2c_sensor: Arc<Mutex<I2CSensor>>) {
    loop {
        let _ = i2c_sensor.lock().unwrap().update().inspect_err(|e| eprintln!("Failed to update sensor. Error: {e}")); // Still need to improve error handling
        println!("{}", i2c_sensor.lock().unwrap());
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}