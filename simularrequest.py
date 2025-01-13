from time import sleep
import requests
import socketio

url = "http://localhost:3001"

dados_package = {
  "id": 0,
  "acel_x": 0,
  "acel_y": 1,
  "acel_z": 2,
  "vel_x": 100,
  "vel_y": 101,
  "vel_z": 102,
  "roll": "-1.4556884765625",
  "pitch": "0.2471923828125",
  "yaw": "143.096923828125",
  "mag_x": "9.84375",
  "mag_y": "-13.16162109375",
  "mag_z": "16.9244384765625",
  "temp": "30.07",
  "esterc": '121.488',
  "rot": '999',
  "veloc": "0",
  "long": "0",
  "lat": "0",
  "press_ar": "0.9970984455958549",
  "altitude": "420",
}

contador = {
  "contador": "0"
}

# teste_url = 'http://localhost:3001/teste'
# print(requests.get(teste_url))
#
# Enviar para Mongo
# NAO ESQUECER DE ACRESCENTAR O ID NO DICIONARIO

sio = socketio.Client()

@sio.event
def connect():
    print("CONECTEI")

sio.connect("http://127.0.0.1:3001")

# Init 
res = requests.post(f'{url}/button_pressed', json=contador)

i = 0

def send_data_package():
    global i
    sio.emit("send", dados_package)
    dados_package["id"]+=i
    dados_package["acel_x"]+=i+1
    dados_package["acel_y"]+=i+2
    dados_package["acel_z"]+=i+3
    
    dados_package["vel_x"]+=i+1
    dados_package["vel_y"]+=i+2
    dados_package["vel_z"]+=i+3
    i+=1

while True:
    send_data_package()
    sleep(1)

# res = requests.post('http://localhost:3001/enviar', json=dados_package)
# print(res.text)
# #
# # Receber todos do Mongo
# dados_all = requests.get('http://localhost:3001/receber')
# print(dados_all.json())

# # Receber por ID do Mongo
# dados_id = requests.get('http://localhost:3000/receber/652adb76d3636ea4e95fa54c')
# print(dados_id.json());

