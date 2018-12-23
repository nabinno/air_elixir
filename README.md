# AirElixir --- Sensor data collector on Raspberry Pi
The AirElixir is a sensor data collector on Raspberry Pi, capable of recording and uploading information about
temperature, humidity, particulate matters, total volatile organic compound, and equivalent calculated carbon-dioxide to
the internet.

## Electronic components (sensor)
| component | manufacture | matters               |
|-----------|-------------|-----------------------|
| DHT11     | Aosong      | temperature, humidity |
| SDS021    | Nova        | PM2.5, PM10           |
| CCS811    | ams         | TVOC, eCO2            |

## Sensor installation
### DHT11
1. Sensor to Raspberry Pi connection
    ```
    GND  <-> GND
    DATA <-> Pin 16
    VCC  <-> 3.3V
    ```

### SDS021: edit the system file for using the serial port
1. Edit file `/boot.cmdline.txt`, delete a characters `console=ttyAMA0,115200`
    ```
    BEFORE: dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
    AFTER:  dwc_otg.lpm_enable=0 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
    ```
2. Edit file `/etc/inittab`, coment the last line of the file
    ```
    # T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100
    ```
3. Sensor to Raspberry Pi connection
    ```
    Red wire    <-> Pin 4
    Black wire  <-> Pin 6
    Yellow wire <-> Pin 8
    Blue wire   <-> Pin 10
    ```

### CCS811: edit the system files for using I2C
1. Enable I2C
    ```sh
    sudo raspi-config
    ```
2. Edit file `/boot/config.txt`, add to tail
    ```sh
    dtparam=i2c_baudrate=10000
    ```
3. Sensor to Raspberry Pi connection
    ```
    VCC     <-> 3.3V
    GND     <-> GND
    I2C SDA <-> pin 2
    I2C SCL <-> pin 3
    WAK     <-> GND
    ```
4. Check that the sensor is wired up correctly
    ```sh
    sudo i2cdetect -y 1
    ```

## Code installation
```sh
git clone https://github.com/nabinno/air_elixir
cd air_elixir
mix deps.get
MIX_ENV=prod mix
GSS_VALUES_APPEND_WEBHOOK={{google-spreadsheets-values-append-webhook}} \
  MIX_ENV=prod \
  nohup elixir --name app@hostname --cookie "AirElixirCookie" -S mix run --no-compile --no-halt &
disown %1
```

---

## Contributing
1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## EPILOGUE
>     A whale!
>     Down it goes, and more, and more
>     Up goes its tail!
>
>     -Buson Yosa
