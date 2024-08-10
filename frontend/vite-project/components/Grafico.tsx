import { useState } from "react";
import "./Grafico.css";

import { MdOutlineToggleOff } from "react-icons/md";
import { MdOutlineToggleOn } from "react-icons/md";
import ChartTeste from "./ChartTeste";


import { io } from 'socket.io-client';

interface Choice {
  velocidade: boolean;
  aceleracao: boolean;
  eixo: boolean;
  outros: boolean;
  rotacao: boolean;
  velRoda: boolean;
}

interface GraficoProps {
  flagShow: boolean;
}

function Grafico({ flagShow }: GraficoProps) {

  let url: string = import.meta.env.VITE_BACKEND_URL;
  url = url.replace("http", "ws"); // Change this to HTTPS if not in localhost

  const socket = io(url);

  const [sensorData, setSensorData] = useState<any>();

  socket.on("send", (response: string) => {
    console.log("Response on line 41", response[0]);
    setSensorData(response[0]);
  });

  const [enumChoice, setEnumChoice] = useState<Choice>({
    velocidade: false,
    aceleracao: false,
    eixo: false,
    outros: false,
    rotacao: false,
    velRoda: false,
  });

  return (
    <>
      {flagShow ? (
        <div className="page-container">
          <div className="container-text">
            <div className="container">
              <div className="opcao">
                <p className="text">VELOCIDADE</p>
                <div className="icons-div">
                  {enumChoice.velocidade ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          velocidade: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          velocidade: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
              <div className="opcao">
                <p className="text">ACELERACAO</p>
                <div className="icons-div">
                  {enumChoice.aceleracao ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          aceleracao: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          aceleracao: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
              <div className="opcao">
                <p className="text">EIXO</p>
                <div className="icons-div">
                  {enumChoice.eixo ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          eixo: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          eixo: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
              <div className="opcao">
                <p className="text">OUTROS</p>
                <div className="icons-div">
                  {enumChoice.outros ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          outros: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          outros: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
              <div className="opcao">
                <p className="text">ROTACAO</p>
                <div className="icons-div">
                  {enumChoice.rotacao ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          rotacao: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          rotacao: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
              <div className="opcao">
                <p className="text">VEL RODA</p>
                <div className="icons-div">
                  {enumChoice.velRoda ? (
                    <MdOutlineToggleOn
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          velRoda: false,
                        }))
                      }
                    />
                  ) : (
                    <MdOutlineToggleOff
                      className="icon-mark"
                      onClick={() =>
                        setEnumChoice((prevState) => ({
                          ...prevState,
                          velRoda: true,
                        }))
                      }
                    />
                  )}
                </div>
              </div>
            </div>
          </div>

          <div className="container-chart">
            <ChartTeste sensor_data={sensorData} enumChoice={enumChoice} />
          </div>
        </div>
      ) : null}
    </>
  );
}

export default Grafico;
