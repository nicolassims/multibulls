import {Socket} from "phoenix";

let socket = new Socket(
  "/socket",
  {params: {token: ""}}
);
socket.connect();

let state = {
  guesses: [],
  gamephase: null,
  winners: [],
  playerscores: new Map(),
};

let username = null;
let channel = null;
let callback = null;

// The server sent us a new state.
function state_update(st) {
  state = st;
  if (callback) {
    callback(st);
  }
}

export function ch_login(usergame) {
  username = usergame.username;
  channel = socket.channel(usergame.gamename, {});
  channel.join()
        .receive("ok", state_update)
        .receive("error", resp => {
          console.log("Unable to join", resp)
        });
}

export function ch_join(cb) {
  callback = cb;
  callback(state);
}

export function ch_push(guess) {
  channel.push("guess", guess)
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

export function ch_reset() {
  channel.push("reset", {})
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}