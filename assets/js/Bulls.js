import React, { useState, useEffect } from 'react';
import 'milligram';

import { ch_join, ch_push, ch_reset } from './socket';

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
  });

  let {guesses} = state;

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

  if (guesses.join("").includes("A4")) {
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
  }

  return (
    <div className="container">
      {body}
    </div>
  );
}

export default Bulls;
