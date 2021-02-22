import React, { useState, useEffect } from 'react';
import 'milligram';

import { ch_login, ch_join, ch_push, ch_reset } from './socket';

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
  const [usergame, setUsergame] = useState(
    {username: "",
    gamename: ""}
  );

  function updateUsername(ev) {
    setUsergame({
      username: ev.target.value, 
      gamename: usergame.gamename});
  };

  function updateGamename(ev) {
    setUsergame({
      username: usergame.username, 
      gamename: ev.target.value});
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
        <button onClick={() => {ch_login(usergame)}}>
          Login
        </button>
      </div>
    </div>
  );
}

function Setup() {
  let roleEnum = {
    OBSERVER : 1,
    READYINGPLAYER : 2,
    READYPLAYER : 3
  }

  const [role, setRole] = useState(roleEnum.OBSERVER);

  function Observer() {
    if (role != roleEnum.OBSERVER) {
      return (
        <button>Become Observer</button>
      )
    } else {
      return null;
    }
  }

  function ReadyPlayer() {
    if (role == roleEnum.READYINGPLAYER) {
      return (
        <button>Become Ready Player</button>
      )
    } else {
      return null;
    }
  }

  function ReadyingPlayer() {
    if (role != roleEnum.READYINGPLAYER) {
      return (
        <button>Become Readying Player</button>
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

function GameOver(props) {
  let {reset} = props;

  return (
    <div className="row">
      <SetTitle text="Game Over!" />
      <div className="column">
        <h1>Game Over!</h1>
        <p>
          <button onClick={reset}>
            Reset
          </button>
        </p>
      </div>
    </div>
  );
}

function YouWin(props) {
  let {reset} = props;

  return (
    <div className="row">
      <SetTitle text="You win!" />
      <div className="column">
        <h1>You win!</h1>
        <p>
          <button onClick={reset}>
            Reset
          </button>
        </p>
      </div>
    </div>
  );
}

function Controls({guess, reset}) {
  const [text, setText] = useState("");

  function updateText(ev) {
    //does this count as game logic being browser-side?
    //I don't think so. This is what professor Tuck did
    //on his Hangman game, roughly
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
            <button onClick={() => guess(text)}>Guess</button>
          </p>
        </div>
        <div className="column">
          <p>
            -- Guesses --
          </p>
        </div>
        <div className="column">
          <p>
            <button onClick={reset}>
              Reset
            </button>
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
    winners: [],
    playerscores: new Map(),
  });

  let {guesses, gamephase, winners, playerscores} = state;

  useEffect(() => {
    ch_join(setState);
  });

  function guess(number) {
    // Inner function isn't a render function
    ch_push({num: number});
  }

  function reset() {
    ch_reset();
  }

  let body = null;

  console.log(state);
  if (gamephase == null) {
    body = <Login />;
  } else {
    body = <Setup />;
  }
  
  /*if (guesses.join("").includes("A4")) {
    body = <YouWin reset={reset} />;
  } else if (guesses.length < 8) {
    body = (
      <div>
        <Controls reset={reset} guess={guess} />
        <div className="row">
          <div className="column">
            <p>{guesses.join('\n')}</p>
          </div>
        </div>  
      </div>
    )
  } else {
    body = <GameOver reset={reset} />;
  }*/

  return (
    <div className="container">
      {body}
    </div>
  );
}

export default Bulls;
