use std::{
    io::Read,
    sync::{Arc, Mutex},
    time::Duration,
};

use rppal::gpio::{Event, Gpio, Trigger};
use rustfied::sensor::{BikeSensor, BluetoothSensor, I2CSensor, UartSensor};

use tokio::sync::Notify;

use rust_socketio::asynchronous::ClientBuilder;

use serde_json::json;

const SERVER_URL: &str = "http://localhost:3001";

#[tokio::main]
async fn main() {
    let mut button_pin = Gpio::new().unwrap().get(26).unwrap().into_input_pullup();

    let sensor = Arc::new(BikeSensor::new("rust_raw_data.txt"));
    let notify = Arc::new(Notify::new());

    let file_sensor_clone = Arc::clone(&sensor);
    let network_clone = Arc::clone(&sensor);

    let uart_sensor = Arc::clone(&sensor.uart);
    let i2c_sensor = Arc::clone(&sensor.i2c);
    let bluetooth_sensor = Arc::clone(&sensor.bluetooth);

    let uart_notify = Arc::clone(&notify);
    let i2c_notify = Arc::clone(&notify);
    let notify_clone = Arc::clone(&notify);

    let is_capturing_data = Arc::new(Mutex::new(false));
    let is_capturing_data_file_clone = Arc::clone(&is_capturing_data);
    let is_capturing_data_network_clone = Arc::clone(&is_capturing_data);

    let interrupt_callback = move |_: Event| {
        dbg!("Button pressed!");
        let mut guard = is_capturing_data.lock().unwrap();
        *guard = !(*guard); // toggle is_capturing_data
    };

    button_pin
        .set_async_interrupt(
            Trigger::FallingEdge,
            Some(Duration::from_millis(50)),
            interrupt_callback,
        )
        .expect("Failed to set interrupt");

    tokio::task::spawn_blocking(move || {
        uart_sensor_task(uart_sensor, uart_notify);
    });

    tokio::task::spawn_blocking(move || {
        i2c_sensor_task(i2c_sensor, i2c_notify);
    });

    let file_handler = tokio::spawn(async move {
        file_task(file_sensor_clone, notify, is_capturing_data_file_clone).await;
    });

    let network_handler = tokio::spawn(async move {
        network_task(network_clone, notify_clone, is_capturing_data_network_clone).await;
    });
    let bluetooth_handler = tokio::spawn(async move {
        bluetooth_sensor_task(bluetooth_sensor).await;
    });
    let _ = tokio::join!(file_handler, network_handler, bluetooth_handler);
}

fn uart_sensor_task(uart_sensor: Arc<Mutex<UartSensor>>, notification: Arc<Notify>) {
    let port_name = "/dev/serial0";
    let baud_rate = 115200;

    let port = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_secs(10))
        .open();

    match port {
        Ok(mut port) => {
            let mut buff_check: Vec<u8> = vec![0; 2];
            loop {
                port.read_exact(&mut buff_check)
                    .expect(" --- IMPROVE ERROR HANDLING --- ");
                // println!("Buff check: {:02x?}", buff_check);
                if buff_check.starts_with(&[0x55, 0x51]) {
                    let mut uart_lock = uart_sensor.lock().unwrap();
                    port.read_exact(&mut uart_lock.buffer[2..])
                        .expect(" --- IMPROVE ERROR HANDLING --- ");
                    // println!("Buff: {:02x?}", uart_lock.buffer);
                    uart_lock.update().expect("Failed to update uart"); // Still need to improve error handling
                    uart_lock.is_ready = true;
                    notification.notify_waiters();
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
            notification.notify_waiters();
        }
        std::thread::sleep(Duration::from_millis(1));
    }
}

async fn bluetooth_sensor_task(bluetooth_sensor: Arc<Mutex<BluetoothSensor>>) {
    loop {
        {
            let mut bluetooth_lock = bluetooth_sensor.lock().unwrap();
            bluetooth_lock.update();
        }
        tokio::time::sleep(Duration::from_millis(200)).await;
    }
}

async fn file_task(
    bike_sensor: Arc<BikeSensor>,
    notification: Arc<Notify>,
    is_capturing_data: Arc<Mutex<bool>>,
) {
    loop {
        if *is_capturing_data.lock().unwrap() {
            notification.notified().await; // wait for notification from sensors
            bike_sensor.write_file().unwrap();
        }
    }
}

async fn network_task(
    bike_sensor: Arc<BikeSensor>,
    notification: Arc<Notify>,
    is_capturing_data: Arc<Mutex<bool>>,
) {
    let duration = Duration::from_millis(250); // Send data aprox. every 250ms
    let mut interval = tokio::time::interval(duration);

    let init_json = json!({
        "contador": 0
    });

    let create_socket = || async {
        ClientBuilder::new(SERVER_URL)
            .namespace("/")
            .connect()
            .await
            .expect("Connection failed")
    };

    let mut socket = create_socket().await;

    reqwest::Client::new()
        .post(format!("{}/button_pressed", SERVER_URL))
        .json(&init_json)
        .send()
        .await
        .expect("Failed to hit /button_pressed route");

    loop {
        if *is_capturing_data.lock().unwrap() {
            notification.notified().await;
            interval.tick().await;
            let sensor_json = bike_sensor.get_json().expect("Failed to parse to json");

            if let Err(e) = socket.emit("send", sensor_json).await {
                println!("Error while trying to send socket: {}", e);
                std::thread::sleep(Duration::from_secs(1));
                socket = create_socket().await;
                std::thread::sleep(Duration::from_secs(1));
            }
            println!("Last line of the loop")
        }
    }
}
