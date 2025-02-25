use std::time::Duration;

const ACCEL_CONST: f32 = 16.0 * 9.8 / 32768.0;

fn main() {

    let port_name = "/dev/ttyUSB0";
    let baud_rate = 9600;


    let port = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_secs(10))
        .open();

    match port {
        Ok(mut port) => {
            let mut buff_check: Vec<u8> = vec![0; 2];
            let mut buffer = init_buffer();        
            loop {
                port.read_exact(&mut buff_check).expect("Failed to read to buff_check");
                if buff_check.starts_with(&[0x55, 0x51]) {
                    port.read_exact(&mut buffer[2..]).expect("Failed to read from buff");
                    println!("Buff: {:02X?}", buffer);
                    let accel = clean_accel(&buffer);
                    println!("Accel: {:#?}", accel);
                } 
            }
        }
        Err(e) => {
            eprintln!("Failed to open \"{}\". Error: {}", port_name, e);
            ::std::process::exit(1);
        }
    }
}

fn clean_accel(raw: &[u8]) -> Vec<f32>{

    let byte1_x = raw.get(2).unwrap();
    let byte2_x = raw.get(3).unwrap();

    let byte1_y = raw.get(4).unwrap();
    let byte2_y = raw.get(5).unwrap();

    let byte1_z = raw.get(6).unwrap();
    let byte2_z = raw.get(7).unwrap();

    let raw_value_x = i16::from_le_bytes([*byte1_x, *byte2_x]);
    let raw_value_y = i16::from_le_bytes([*byte1_y, *byte2_y]);
    let raw_value_z = i16::from_le_bytes([*byte1_z, *byte2_z]);

    let accel_x = raw_value_x as f32 * ACCEL_CONST;
    let accel_y = raw_value_y as f32 * ACCEL_CONST;
    let accel_z = raw_value_z as f32 * ACCEL_CONST;

    vec![accel_x, accel_y, accel_z]
}

fn init_buffer() -> Vec<u8> {
    let mut buff: Vec<u8> = vec![0; 42];
    buff.insert(0, 0x55);
    buff.insert(1, 0x51);
    
    buff
}