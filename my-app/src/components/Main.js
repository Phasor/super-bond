import React, { useState } from 'react'
import '../css/Main.css'
import Borrow from './Borrow';
import Lend from './Lend';

export default function Main() {
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
                    <button className="main-content-tabs-button" onClick={changeTab}>Borrow</button>
                    <button className="main-content-tabs-button" onClick={changeTab}>Lend</button>
                </div>
                <div className="main-content-form">
                    {tab === "borrow" && <Borrow/>} 
                    {tab === "lend" && <Lend/>} 
                </div>
            </div>
        </div>
  
  )
}
