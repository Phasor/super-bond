import React, {useState} from 'react'
import '../css/Borrow.css';
import { useWeb3React } from '@web3-react/core';
//import { formatEther } from '@ethersproject/units';
import {abi} from "../abi";
import {useContract} from '../Hooks/useContract';

export default function Borrow(props) {
  const [amountToRaise, setAmountToRaise] = useState();
  const [rate, setRate] = useState();
  const [term, setTerm] = useState();
  const [admin,setAdmin] = useState();
  const {
    account,
    activate,
    active,
    chainId,
    connector,
    deactivate,
    error,
    provider,
    setError,
    library,
} = useWeb3React();
  
  const contractAddress = "0x48e231fA9bC484980D7e90f14a6CdcF07aBbd90E";
  const bondContract = useContract(contractAddress, abi);
  

  const handleSubmit = (e) => {
    e.preventDefault();
    setAmountToRaise(e.target.amount.value);
    setRate(e.target.interestRateAnnual.value);
    setTerm(e.target.termDays.value);
    console.log("Amount: " + amountToRaise + "\nRate: " + rate + "\nTerm: " + term);
  }

  const changeAdmin = async (e) => {
    e.preventDefault();
    if(active){
      const txn = await bondContract.setAdmin(e.target.newAdmin.value);
      console.log("Txn: " + {txn});

      //fetch latest admin value from chain
      const newAdmin = await bondContract.admin();
      console.log("New admin is: " + {newAdmin});
    }
  }

  return (
      <div className='borrow-container'>
        <form 
          className='borrow-form'
          onSubmit={handleSubmit}
        >
            <div className="form-row">
              <label htmlFor="">Amount to Raise ($)</label>
              <input type="text" 
                  required
                  name="amount"
                  value={amountToRaise}
                  onChange={(e) => {setAmountToRaise(e.target.value)}}
              />
          </div>
            <div className="form-row">
              <label htmlFor="">Interest Paid Annually (%)</label>
              <input type="text" 
                  required
                  name="interestRateAnnual"
                  value={rate}
                  onChange={(e) => {setRate(e.target.value)}}
              />
            </div>
            <div className="form-row">
              <label htmlFor="">Loan Term (days)</label>
              <input type="text" 
                  required
                  name="termDays"
                  value={term}
                  onChange={(e) => {setTerm(e.target.value)}}
              />
            </div>
            <div className='button-deploy-container'>
              <button className='button-deploy'>Deploy Loan</button>
            </div>
          
       </form>
       <div>
        <form onSubmit={changeAdmin}>
          <label>Change Admin</label>
          <input type="text" 
            value={admin}
            name="newAdmin"
            onChange={(e) => {setAdmin(e.target.newAdmin.value)}} />
          <button>Change</button>
        </form>
       </div>
       
       
    </div>
  )
}
