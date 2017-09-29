pragma solidity ^0.4.15;

import "../PrivateCall.sol";

 /**
   @title Unit, contract for a unit in the inventory of a hotel contract

   A contract that represents a hotel unit in the WT network, it stores the
   unit avaliability and special prices.
   Uses PrivateCall contract developed by WT.
 */
contract Unit is PrivateCall {

  // The type of the unit
  bytes32 public unitType;

  // The status of the unit
  bool public active;

  // An array of all days avaliability after 01-01-1970
  mapping(uint => UnitDay) reservations;
  struct UnitDay {
    string specialPrice;
    address bookedBy;
  }

  /**
     @dev Event triggered on every booking done
  **/
  event Book(address from, uint fromDay, uint daysAmount);

  /**
     @dev Constructor. Creates the unit contract in active status

     @param _owner see `owner`
     @param _unitType see `unitType`
   */
  function Unit(address _owner, bytes32 _unitType){
    owner = _owner;
    unitType = _unitType;
    active = true;
  }

  /**
     @dev `setActive` allows the owner of the contract to change the status

     @param _active The new status of the unit
   */
  function setActive(bool _active) onlyOwner() {
    active = _active;
  }

  /**
     @dev `setPrice` allows the owner of the contract to set a price for
     a period of time.

     @param price The price of the unit
     @param fromDay The starting day of the period of days to change
     @param daysAmount The amount of days in the period
   */
  function setPrice(
    string price,
    uint fromDay,
    uint daysAmount
  ) onlyOwner() {
    uint toDay = fromDay+daysAmount;
    for (uint i = fromDay; i < toDay; i++)
      reservations[i].specialPrice = price;
  }

  /**
     @dev `setPrice` allows the contract to execute a book function itself.

     @param from The address of the oener of the reservation
     @param fromDay The starting day of the period of days to book
     @param daysAmount The amount of days in the booking period
     @param finalDataCall A data to execute a call on the hotel contract
     taht owns this unit
   */
  function book(
    address from,
    uint fromDay,
    uint daysAmount,
    bytes finalDataCall
  ) fromSelf() {
    require(active);
    bool canBook = true;
    uint toDay = fromDay+daysAmount;

    for (uint i = fromDay; i <= toDay ; i++){
      if (reservations[i].bookedBy != address(0)) {
        canBook = false;
        break;
      }
    }

    if (canBook){
      for (i = fromDay; i <= toDay ; i++)
        reservations[i].bookedBy = from;
      Book(from, fromDay, toDay);
      owner.call(finalDataCall);
    }
  }

  /**
     @dev `getReservation` get the avalibility and price of a day.

     @param day The number of days after 01-01-1970

     @return string The price of the day
     @return address The address of the owner of the reservation
     returns 0x0 if its available
   */
  function getReservation(
    uint day
  ) constant returns(string, address) {
    return (
      reservations[day].specialPrice,
      reservations[day].bookedBy
    );
  }

}
