import React, { useState, useEffect } from 'react';
import 'milligram';

import { ch_ping, ch_changerole, ch_login, ch_join, ch_push, ch_reset } from './socket';

function SetTitle({text}) {
  useEffect(() => {
    let orig = document.title;
    document.title = text;

    // Cleanup function
    return () => {
      document.title = orig;
    };
  });

  return <div />;
}

function Login() {
  /*Game names and user names must be 
    composed exclusively of letters.
    This is a controlled input.*/
  const [usergame, setUsergame] = useState(
    {username: "",
    gamename: ""}
  );

  function updateUsername(ev) {
    let vv = ev.target.value;

    if (!/^[a-zA-Z]+$/.test(vv)) {
      vv = vv.substring(0, vv.length - 1);
    }

    setUsergame({
      username: vv, 
      gamename: usergame.gamename});
  };

  function updateGamename(ev) {
    let vv = ev.target.value;

    if (!/^[a-zA-Z]+$/.test(vv)) {
      vv = vv.substring(0, vv.length - 1);
    }
   
    setUsergame({
      username: usergame.username, 
      gamename: vv});
  };

  return (
    <div>
      <div className="row">
        <SetTitle text="Logging in..." />
        <div className="column">
          <h3>Enter Username</h3>
          <input value={usergame.username}
                  onChange={updateUsername}
                  type="text" />
        </div>
        <div className="column">
          <h3>Enter Game Name</h3>
          <input value={usergame.gamename}
                  onChange={updateGamename}
                  type="text" />
        </div>
      </div>
      <div className="row">
        <div className="column">
          <button onClick={() => {ch_login(usergame)}}>
            Login
          </button>
        </div>
      </div>
    </div>
  );
}

function Setup() {
  const [role, setRole] = useState("observer");

  function changeRole(role) {
    setRole(role);
    ch_changerole(role);
  }

  function Observer() {
    if (role != "observer") {
      return (
        <button onClick={() => changeRole("observer")}>
            Become Observer
        </button>
      )
    } else {
      return null;
    }
  }

  function ReadyPlayer() {
    if (role == "readyingplayer") {
      return (
        <button onClick={() => changeRole("readyplayer")}>
          Become Ready Player
        </button>
      )
    } else {
      return null;
    }
  }

  function ReadyingPlayer() {
    if (role != "readyingplayer") {
      return (
        <button onClick={() => changeRole("readyingplayer")}>
          Become Readying Player
        </button>
      )
    } else {
      return null;
    }
  }

  return (
    <div>
      <div className="row">
        <SetTitle text="Selecting Role" />
        <div className="column">
          <Observer />
        </div>
        <div className="column">
          <ReadyPlayer />
        </div>
        <div className="column">
          <ReadyingPlayer />
        </div>
      </div>
    </div>
  );
}

function Controls({guess, _reset}) {
  const [text, setText] = useState("");

  function updateText(ev) {
    let vv = ev.target.value;
    if (vv.length > 4) {
      vv = vv.substring(0, 4);
    }
    setText(vv);
  }

  function keyPress(ev) {
    if (ev.key == "Enter") {
      guess(text);
    }
  }

  return (
    <div>
      <div className="row">
        <div className="column">
          <p>
            <input type="text"
                  value={text}
                  onChange={updateText}
                  onKeyPress={keyPress} />
          </p>
        </div>
      </div>
      <div className="row">
        <div className="column">
          <p>
            <button onClick={() => { guess(text); setText("")}}>Guess</button>
          </p>
        </div>
        <div className="column">
          <p>-- Guesses --</p>
        </div>
        <div className="column">
          <p>
            <button onClick={() => guess("pass")}>Pass</button>
          </p>
        </div>
      </div>
    </div>
  );
}

function Bulls() {
  const [state, setState] = useState({
    guesses: [],
    gamephase: null,
    lastwinners: [],
    userstats: new Map(),
    roundtime: 30
  });

  let {guesses, gamephase, lastwinners, userstats, roundtime} = state;

  useEffect(() => {
    ch_join(setState);
  });

  function guess(number) {
    // Inner function isn't a render function
    ch_push({num: number});
  }

  function reset() {
    let newstate = Object.assign({}, state, {gamephase: null});
    setState(newstate);
    ch_reset();
  }

  function interpretguesses(strguesses) {
    strguesses = strguesses.split("}");
    let newmap = new Map();
    for (let i = 0; i < strguesses.length - 1; i++) {
      let bracepos = strguesses[i].indexOf("{\"") + 2;
      let spacepos = strguesses[i].indexOf("\", ");
      let key = strguesses[i].substring(bracepos, spacepos);

      let openpos = strguesses[i].indexOf('["') + 2;
      let closepos = strguesses[i].indexOf("]") - 1;
      let data = strguesses[i].substring(openpos, closepos).split(",");
      newmap.set(key, data);
    }

    let bodypart = [];

    function drawGuesses(data, mapkey, map) {
      bodypart.push([
        <div key={mapkey} className="column">
          <p>{mapkey}</p>
          <p>{data.join('\n').replace(/\\"|"|\| ni/g, '')}</p>
        </div>
      ])
    }

    newmap.forEach(drawGuesses);

    return bodypart;
  }

  function interpretuserstats(usrstats) {
    let bodypart = [];

    function drawStats(data, mapkey, map) {
      bodypart.push([
        <div key={mapkey} className="column">
          <p>{mapkey}: W{data[0]}/L{data[1] - data[0]}</p>
        </div>
      ]);
    }

    usrstats = new Map(Object.entries(usrstats));
    usrstats.forEach(drawStats);

    return bodypart;
  }

  let body = null;

  console.log(state);
  if (gamephase == null) {
    body = <Login />;
  } else if (gamephase == "setup") {
    body = (
      <div>
        <div className="row">
          <div className="col">
            Prior Winners: {lastwinners.join(", ")}
          </div>
        </div>
        <div className="row">
          {interpretuserstats(userstats)}
        </div>
        <Setup />
      </div>
    );
  } else {
    body = (
      <div>
        {roundtime} seconds left!
        <Controls guess={guess} />
        <div className="row">
          {interpretguesses(guesses)}
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <button onClick={reset}>
        Log Out
      </button>
      {body}
    </div>
  );
}

export default Bulls;
