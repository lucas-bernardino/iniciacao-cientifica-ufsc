use dotenv::dotenv;
use lettre::{
    message::header::ContentType, transport::smtp::authentication::Credentials, Message,
    SmtpTransport, Transport,
};
use std::process::{exit, Command, Stdio};

const BACKEND_ENV_PATH: &str = "../backend/.env";
const VITE_ENV_PATH: &str = "../frontend/vite-project/.env";

fn main() {
    dotenv().ok();
    let url = match get_url() {
        Ok(url) => url,
        Err(e) => {
            println!("ERROR: Could not get url from zrok overview:\n{e}");
            exit(1);
        }
    };
    println!("URL: {url}");
    match send_email(&url) {
        Ok(_) => println!("Successfuly send email"),
        Err(e) => println!("ERROR: Could not send email:\n{e}"),
    };
    match change_url_backend_env("katiau") {
        Ok(_) => println!("Successfully change url in backend .env"),
        Err(e) => println!("ERROR: Could not change url in backend .env:\n{e}"),
    }
    match change_url_frontend_env("vrum", "bibi") {
        Ok(_) => println!("Successfully change url in frontend .env"),
        Err(e) => println!("ERROR: Could not change url in frontend .env:\n{e}"),
    }
}

fn get_url() -> Result<String, Box<dyn std::error::Error + 'static>> {
    let zrok_release = Command::new("zrok")
        .arg("overview")
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to spawn zrok overview")
        .wait_with_output()
        .expect("Failed to get output from zrok overview");

    let output = std::str::from_utf8(&zrok_release.stdout)
        .expect("Problem occurred when getting zrok release output")
        .replace(r"\", "");

    let output_json: serde_json::Value = serde_json::from_str(output.as_str()).unwrap();

    let mut sorted_by_creation = output_json["environments"][0]["shares"]
        .as_array()
        .expect("Failed to get array out of urls")
        .clone();
    sorted_by_creation.sort_by_key(|key| key["createdAt"].as_i64());

    let latest_url = sorted_by_creation
        .last()
        .expect("Failed to get last element in array")["frontendEndpoint"]
        .clone();

    Ok(latest_url.to_string())
}

fn send_email(url: &String) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let email = Message::builder()
        .from("projetomotobmw@gmail.com".parse()?)
        .to("projetomotobmw@gmail.com".parse()?)
        .subject("API")
        .header(ContentType::TEXT_PLAIN)
        .body(url.clone())?;

    let password = std::env::var("GMAIL_PASSWORD")
        .expect("Missing GMAIL_PASSWORD in .env file!")
        .replace("_", " ");

    let creds = Credentials::new("projetomotobmw@gmail.com".to_owned(), password.to_owned());

    let mailer = SmtpTransport::relay("smtp.gmail.com")
        .unwrap()
        .credentials(creds)
        .build();

    match mailer.send(&email) {
        Ok(_) => println!("Email sent successfully!"),
        Err(e) => panic!("Could not send email: {e:?}"),
    }

    Ok(())
}

fn change_url_backend_env(backend_url: &str) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let mut old_info_backend = std::fs::read_to_string(BACKEND_ENV_PATH)?;
    let offset = old_info_backend.rfind('=').unwrap();
    old_info_backend.replace_range(offset.., format!("={val}", val = backend_url).as_str());
    std::fs::write(BACKEND_ENV_PATH, &old_info_backend)?;
    Ok(())
}

fn change_url_frontend_env(
    backend_url: &str,
    flask_url: &str,
) -> Result<(), Box<dyn std::error::Error + 'static>> {
    let string_on_vite_env = format!(
        "VITE_BACKEND_URL={}\nVITE_FLASK_URL={}",
        backend_url, flask_url
    );
    std::fs::write(VITE_ENV_PATH, &string_on_vite_env)?;
    Ok(())
}
