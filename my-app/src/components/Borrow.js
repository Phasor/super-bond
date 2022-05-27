import React, {useState} from 'react'
import '../css/Borrow.css';


export default function Borrow(props) {
  const [amountToRaise, setAmountToRaise] = useState();
  const [rate, setRate] = useState();
  const [term, setTerm] = useState();
  
  const handleSubmit = () => {

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
                  value={amountToRaise}
                  onChange={(e) => {setAmountToRaise(e.target.value)}}
              />
          </div>
            <div className="form-row">
              <label htmlFor="">Interest Paid Annually (%)</label>
              <input type="text" 
                  required
                  value={rate}
                  onChange={(e) => {setRate(e.target.value)}}
              />
            </div>
            <div className="form-row">
              <label htmlFor="">Loan Term (days)</label>
              <input type="text" 
                  required
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
