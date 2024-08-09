import requests
import socketio

dados_package = {
  "id": "0",
  "acel_x": "0",
  "acel_y": "0",
  "acel_z": "0",
  "vel_x": "100",
  "vel_y": "100",
  "vel_z": "100",
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
  "altitude": "6969",
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
    my_message('a')

@sio.event
def my_message(data):
    print('message received with ', data)
    res = requests.post('http://localhost:3001/button_pressed', json=contador)
    print(res.text)
    sio.emit('foo', dados_package)

sio.connect("http://127.0.0.1:3001")
sio.wait()
#
res = requests.post('http://localhost:3001/button_pressed', json=contador)
print(res.text)

print("fim")

# res = requests.post('http://localhost:3001/enviar', json=dados_package)
# print(res.text)
# #
# # Receber todos do Mongo
# dados_all = requests.get('http://localhost:3000/receber')
# print(dados_all.json())

# # Receber por ID do Mongo
# dados_id = requests.get('http://localhost:3000/receber/652adb76d3636ea4e95fa54c')
# print(dados_id.json());

