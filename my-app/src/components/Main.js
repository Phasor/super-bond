import React, { useState } from 'react'
import '../css/Main.css'
import Borrow from './Borrow';
import Lend from './Lend';

export default function Main(props) {
    const [tab, setTab] = useState("borrow");
  
    const changeTab = () => {
        if(tab === "borrow"){
            setTab("lend");
        }else{
            setTab("borrow");
        }
    }
    return (
      
        <div className="main-container">
            <div className="main-content">
                <div className="main-content-tabs">
                    <button className={`main-content-tabs-button ${tab === "borrow" ? "active" : ""}`} onClick={changeTab}>Borrow</button>
                    <button className={`main-content-tabs-button ${tab === "lend" ? "active" : ""}`} onClick={changeTab}>Lend</button>
                </div>
                <div className="main-content-form">
                    {tab === "borrow" && <Borrow provider={props.provider} signer={props.signer}/>} 
                    {tab === "lend" && <Lend provider={props.provider} signer={props.signer}/>} 
                </div>
            </div>
        </div>
  
  )
}
