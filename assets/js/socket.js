import {Socket} from "phoenix";

let socket = new Socket(
  "/socket",
  {params: {token: ""}}
);
socket.connect();

let state = {
  guesses: [],
  gamephase: null,
  lastwinners: [],
  userstats: new Map(),
  roundtime: 30,
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
  channel = socket.channel("game:" + usergame.gamename, username);
  channel.on("view", state_update);
  console.log("Joining channel");
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
  channel.push("reset", username)
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
  state.gamephase = null;
  channel.leave();
}

export function ch_changerole(role) {
  let newmap = new Map()
  newmap['user'] = username;
  newmap['role'] = role;
  channel.push("change role", newmap)
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

export function ch_ping() {
  channel.push("ping", guess)
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}