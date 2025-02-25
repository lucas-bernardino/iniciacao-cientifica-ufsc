const ACCEL_CONST: f32 = 16.0 * 9.8 / 32768.0;
const VEL_CONST: f32 = 2000.0 / 32768.0;
const ANGLE_CONST: f32 = 180.0 / 32768.0;

pub fn clean_accel(raw: &[u8]) -> Result<[f32; 3], &'static str>{
    let [raw_accel_x, raw_accel_y, raw_accel_z] = get_raw_xyz_values(raw)?[..] else {return Err("Failed to destruct vec")};
    
    let accel_x = raw_accel_x as f32 * ACCEL_CONST;
    let accel_y = raw_accel_y as f32 * ACCEL_CONST;
    let accel_z = raw_accel_z as f32 * ACCEL_CONST;

    Ok([accel_x, accel_y, accel_z])
}


pub fn clean_vel(raw: &[u8]) -> Result<[f32; 3], &'static str>{
    let [raw_vel_x, raw_vel_y, raw_vel_z] = get_raw_xyz_values(raw)?[..] else {return Err("Failed to destruct vec")};
    
    let vel_x = raw_vel_x as f32 * VEL_CONST;
    let vel_y = raw_vel_y as f32 * VEL_CONST;
    let vel_z = raw_vel_z as f32 * VEL_CONST;

    Ok([vel_x, vel_y, vel_z])
}

pub fn clean_angle(raw: &[u8]) -> Result<[f32; 3], &'static str>{
    let [raw_angle_x, raw_angle_y, raw_angle_z] = get_raw_xyz_values(raw)?[..] else {return Err("Failed to destruct vec")};
    
    let angle_x = raw_angle_x as f32 * ANGLE_CONST;
    let angle_y = raw_angle_y as f32 * ANGLE_CONST;
    let angle_z = raw_angle_z as f32 * ANGLE_CONST;

    Ok([angle_x, angle_y, angle_z])
}

fn get_raw_xyz_values(raw: &[u8]) -> Result<[i16; 3], &'static str> {
    let byte1_x = raw.get(2).ok_or("Missing byte")?;
    let byte2_x = raw.get(3).ok_or("Missing byte")?;

    let byte1_y = raw.get(4).ok_or("Missing byte")?;
    let byte2_y = raw.get(5).unwrap();

    let byte1_z = raw.get(6).ok_or("Missing byte")?;
    let byte2_z = raw.get(7).ok_or("Missing byte")?;

    let raw_value_x = i16::from_le_bytes([*byte1_x, *byte2_x]);
    let raw_value_y = i16::from_le_bytes([*byte1_y, *byte2_y]);
    let raw_value_z = i16::from_le_bytes([*byte1_z, *byte2_z]);

    Ok([raw_value_x, raw_value_y, raw_value_z])
}