use std::{io::Write, sync::{Arc, Mutex}, time::Duration};

use rustfied::sensor::{BikeSensor, UartSensor, I2CSensor};

use tokio::sync::Notify;

#[tokio::main]
async fn main() {

    let sensor = Arc::new(BikeSensor::new("rust_raw_data.txt"));
    let notify = Arc::new(Notify::new());

    let uart_sensor = Arc::clone(&sensor.uart);
    let uart_notify = Arc::clone(&notify);

    let i2c_sensor = Arc::clone(&sensor.i2c);
    let i2c_notify = Arc::clone(&notify);

    let file_sensor_clone = Arc::clone(&sensor);

    tokio::task::spawn_blocking(move || {
        uart_sensor_task(uart_sensor, uart_notify);
    });

    tokio::task::spawn_blocking(move || {
        i2c_sensor_task(i2c_sensor, i2c_notify);
    }); 

    tokio::spawn(async move {
        file_task(file_sensor_clone, notify).await;
    }).await.unwrap();

}

fn uart_sensor_task(uart_sensor: Arc<Mutex<UartSensor>>, notification: Arc<Notify>) {
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
                    notification.notify_one();
                } 
            }
        }
        Err(e) => {
            eprintln!("Failed to open \"{}\". Error: {}", port_name, e);
            ::std::process::exit(1);
        }
    } 
}

fn i2c_sensor_task(i2c_sensor: Arc<Mutex<I2CSensor>>, notification: Arc<Notify>) {
    loop {
        {
            let mut i2c_lock = i2c_sensor.lock().unwrap();
            i2c_lock.update().expect("Failed to update i2c"); // Still need to improve error handling
            
            i2c_lock.is_ready = true;
            notification.notify_one();
        }
        
        std::thread::sleep(Duration::from_millis(1));
    }
}

async fn file_task(bike_sensor: Arc<BikeSensor>, notification: Arc<Notify>) {
    loop {
        notification.notified().await; // wait for notification from sensors
        bike_sensor.write_file().unwrap();
    }
}