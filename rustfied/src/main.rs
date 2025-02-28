use std::{io::Write, sync::{Arc, Mutex}, time::Duration};

use rustfied::sensor::{BikeSensor, UartSensor, I2CSensor};

#[tokio::main]
async fn main() {
    let sensor = Arc::new(BikeSensor::new());

    let file = std::fs::File::create("rust_raw_data.txt").expect("Failed to create file");

    let uart_sensor = Arc::clone(&sensor.uart);
    let i2c_sensor = Arc::clone(&sensor.i2c);
    let file_sensor_clone = Arc::clone(&sensor);

    tokio::task::spawn_blocking(move || {
        uart_sensor_task(uart_sensor);
    });

    tokio::task::spawn_blocking(move || {
        i2c_sensor_task(i2c_sensor);
    }); 

    tokio::spawn(async move {
        file_task(file, file_sensor_clone).await;
    }).await.unwrap();

}

fn uart_sensor_task(uart_sensor: Arc<Mutex<UartSensor>>) {
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
                    let mut uart_lock = uart_sensor.lock().unwrap();
                    port.read_exact(&mut uart_lock.buffer[2..]).expect(" --- IMPROVE ERROR HANDLING --- ");
                    uart_lock.update().expect("Failed to update uart"); // Still need to improve error handling

                    uart_lock.is_ready = true; 
                } 
            }
        }
        Err(e) => {
            eprintln!("Failed to open \"{}\". Error: {}", port_name, e);
            ::std::process::exit(1);
        }
    } 
}

fn i2c_sensor_task(i2c_sensor: Arc<Mutex<I2CSensor>>) {
    loop {
        {
            let mut i2c_lock = i2c_sensor.lock().unwrap();
            i2c_lock.update().expect("Failed to update i2c"); // Still need to improve error handling
            i2c_lock.is_ready = true;
        }
        
        std::thread::sleep(Duration::from_millis(1));
    }
}

async fn file_task(mut file: std::fs::File, bike_sensor: Arc<BikeSensor>) {
    loop {
        let mut data_uart = bike_sensor.uart.lock().unwrap();
        let mut data_i2c = bike_sensor.i2c.lock().unwrap();

        if data_uart.is_ready == true && data_i2c.is_ready == true {
            file.write(format!("{} | {}\n", data_uart, data_i2c).as_bytes()).expect("Failed to write to file");

            data_uart.is_ready = false;
            data_i2c.is_ready = false;
        }
    }
}