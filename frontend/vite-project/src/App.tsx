import "./App.css";
import Sensor from "../components/Sensor";
import Action from "../components/Action";

import { io } from 'socket.io-client';

function App() {
  let url: string = import.meta.env.VITE_BACKEND_URL;
  url = url.replace("http", "ws"); // Change this to HTTPS if not in localhost

  let socket = io(url);

  return (
    <div className="app">
      <div className="sensor-div">
        <Sensor socket={socket} />
      </div>
      <div className="div-action">
        <Action />
      </div>
    </div>
  );
}

export default App;

