#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <erl_nif.h>
#include <wiringPi.h>

#define MAX_TIME 85

static int dht11_pin;
static int dht11_data[5] = {0, 0, 0, 0, 0};

static ERL_NIF_TERM setup(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  if (wiringPiSetup() == -1)
    exit(EXIT_FAILURE);
  if (setuid(getuid()) < 0)
    exit(EXIT_FAILURE);

  return enif_make_atom(env, "ok");
}

static ERL_NIF_TERM dht11_read(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[]) {
  enif_get_int(env, argv[0], &dht11_pin);

  uint8_t lststate = HIGH;
  uint8_t counter = 0;
  uint8_t j = 0, i;

  for (i = 0; i < 5; i++)
    dht11_data[i] = 0;
  pinMode(dht11_pin, OUTPUT);
  digitalWrite(dht11_pin, HIGH);
  delay(40);
  digitalWrite(dht11_pin, LOW);
  delayMicroseconds(18);

  pinMode(dht11_pin, INPUT);

  for (i = 0; i < MAX_TIME; i++) {
    counter = 0;
    while (digitalRead(dht11_pin) == lststate) {
      counter++;
      delayMicroseconds(1);
      if (counter == 255)
        break;
    }
    lststate = digitalRead(dht11_pin);
    if (counter == 255)
      break;
    if ((i >= 4) && (i % 2 == 0)) {
      dht11_data[j / 8] <<= 1;
      if (counter > 16)
        dht11_data[j / 8] |= 1;
      j++;
    }
  }

  if ((j >= 40) && (dht11_data[4] == ((dht11_data[0] + dht11_data[1] +
                                       dht11_data[2] + dht11_data[3]) &
                                      0xFF))) {
    return enif_make_tuple(
        env, 2, enif_make_atom(env, "ok"),
        enif_make_tuple(env, 2, enif_make_double(env, dht11_data[0]),
                        enif_make_double(env, dht11_data[2])));
  } else {
    return enif_make_tuple(
        env, 2, enif_make_atom(env, "error"),
        enif_make_string(env, "checksum mismatch", ERL_NIF_LATIN1));
  }
}

static ErlNifFunc nif_funcs[] = {{"setup", 0, setup}, {"read", 1, dht11_read}};

ERL_NIF_INIT(Elixir.Dht11.ReadByC, nif_funcs, NULL, NULL, NULL, NULL)
