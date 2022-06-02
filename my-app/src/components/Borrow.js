import React, {useState} from 'react'
import '../css/Borrow.css';
import { useWeb3React } from '@web3-react/core';
import { formatEther } from '@ethersproject/units';
import {abi} from "../abi";
import {ethers} from 'ethers';

export default function Borrow(props) {
  const [amountToRaise, setAmountToRaise] = useState();
  const [rate, setRate] = useState();
  const [term, setTerm] = useState();
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
  const bondContract = new ethers.Contract(contractAddress, abi, library);
  
  const handleSubmit = (e) => {
    e.preventDefault();
    setAmountToRaise(e.target.amount.value);
    setRate(e.target.interestRateAnnual.value);
    setTerm(e.target.termDays.value);
    console.log("Amount: " + amountToRaise + "\nRate: " + rate + "\nTerm: " + term);
  }

  const balance = async () => {
    var balance = await library.getBalance( account );
    console.log(formatEther(balance));
    var rateFromChain = await bondContract._loanTerm();
    console.log(rateFromChain/(10**18));
  }

  balance();

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
       
       
    </div>
  )
}
