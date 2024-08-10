import "./Sensor.css";
import { useEffect, useState } from "react";

interface ISocket {
  socket: any
}

function Sensor({ socket }: ISocket) {
  const [sensorData, setSensorData] = useState<any>([]);

  let url: string = import.meta.env.VITE_BACKEND_URL;
  url = url.replace("http", "ws"); // Change this to HTTPS if not in localhost

  useEffect(() => {
    socket.on("send", (response: string) => {
      setSensorData(response);
    });
    return () => {
      socket.off("send");
    }
  }, [])

  return (
    <div className="sensor-container">
      <div className="sensor-box">
        <div className="sensor-title"> Vel. Angular</div>
        <div className="sensor-data-title">
          Velocidade Angular X
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["vel_x"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Velocidade Angular Y
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["vel_y"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Velocidade Angular Z
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["vel_z"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Módulo
          <div className="sensor-data-value">
            {sensorData &&
              Number(
                Math.sqrt(
                  sensorData["vel_x"] ** 2 +
                  sensorData["vel_y"] ** 2 +
                  sensorData["vel_z"] ** 2,
                ),
              ).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Aceleração </div>
        <div className="sensor-data-title">
          Aceleração X
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["acel_x"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Aceleração Y
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["acel_y"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Aceleração Z
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["acel_z"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Módulo
          <div className="sensor-data-value">
            {sensorData &&
              Number(
                Math.sqrt(
                  sensorData["acel_x"] ** 2 +
                  sensorData["acel_y"] ** 2 +
                  sensorData["acel_z"] ** 2,
                ),
              ).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Eixo </div>
        <div className="sensor-data-title">
          Roll
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["roll"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Pitch
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["pitch"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Yaw
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["yaw"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Módulo
          <div className="sensor-data-value">
            {sensorData &&
              Number(
                Math.sqrt(
                  sensorData["roll"] ** 2 +
                  sensorData["pitch"] ** 2 +
                  sensorData["yaw"] ** 2,
                ),
              ).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Magnético </div>
        <div className="sensor-data-title">
          Magnético X
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["mag_x"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Magnético Y
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["mag_y"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Magnético Z
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["mag_z"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Módulo
          <div className="sensor-data-value">
            {sensorData &&
              Number(
                Math.sqrt(
                  sensorData["mag_x"] ** 2 +
                  sensorData["mag_y"] ** 2 +
                  sensorData["mag_z"] ** 2,
                ),
              ).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Esterçamento </div>
        <div className="sensor-data-title">
          Graus
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["esterc"]).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Rotações </div>
        <div className="sensor-data-title">
          RPM
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["rot"]).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Temperatura </div>
        <div className="sensor-data-title">
          Temperatura Atual
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["temp"]).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Velocidade </div>
        <div className="sensor-data-title">
          Velocidade Linear Atual
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["veloc"]).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Posição </div>
        <div className="sensor-data-title">
          Longitude:
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["long"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Latitude:
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["lat"]).toFixed(2)}
          </div>
        </div>
      </div>

      <div className="sensor-box">
        <div className="sensor-title"> Pressão </div>
        <div className="sensor-data-title">
          Velocidade Roda:
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["press_ar"]).toFixed(2)}
          </div>
        </div>
        <div className="sensor-data-title">
          Altitude:
          <div className="sensor-data-value">
            {sensorData && Number(sensorData["altitude"]).toFixed(2)}
          </div>
        </div>
      </div>
    </div>
  );
}

export default Sensor;
