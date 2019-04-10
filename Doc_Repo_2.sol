pragma solidity ^0.5.0;

/*Smart contract to store customer basic information where customers can register their details and authority can verify them and use them */
contract KYCRepo {
  //for customer perosonal information
  struct identity{
    string name;
    string contact;
  }
  //for customer address details
  struct cust_address{
    string add;
  }
  //main customer structure
  struct customer{
    identity identity_details;
    cust_address address_details;
    bool varified;
    uint8 status;
    address cust_id;
    uint weight;
  }
//banks for access user information
  struct banks{
    address bk_id;
    string name;
    string ifsc;
  }

  address authority;//main contract deployer (admin)
  address[] non_verified_customers_adresses;//holds non verified customers address
  address[] verified_customers_adresses;//holds verified customers address
  address[] bank_addresses;//holds banks address
  mapping (address=>customer) all_customers;//all customers details
  mapping (address=>banks) all_banks;//all bank details

  constructor() public {
    authority=msg.sender;
  }
  //for banks registration 
  function registerBank(address bad,string memory nm,string memory ifs) public{
    require(authority==msg.sender,"Only authority can use this function");//for authority only validation
    require(!validBankAddress(bad) ,"bank already registered!!");//for checking collision with existing bank
    all_banks[bad]=banks({
      bk_id:bad,
      name:nm,
      ifsc:ifs
    });
    bank_addresses.push(bad);//push the bank address
  }
  //for get the bank details based on bank address
  function getBank(address ad)public view returns(address,string memory,string memory){
      require(validBankAddress(ad),"Not valid bank address");
      banks memory b=all_banks[ad];
      return (b.bk_id,b.name,b.ifsc);
  }
  //for checking validity of bank
  function validBankAddress(address ad) public view returns(bool) {
    bool flg=false;
    for (uint index = 0; index < bank_addresses.length; index++) {
      if(ad==bank_addresses[index]){
        flg=true;
        break;
      }
    }
    return flg;
  }
  //for customer registration done by any customer
  function register(string memory nm,string memory con,string memory ad) public payable returns(address){
    require(all_customers[msg.sender].weight!=1 ,"cusotmer already registered!!");//for existing customer
    non_verified_customers_adresses.push(msg.sender);
    all_customers[msg.sender]=customer({
      identity_details:identity({
        name:nm,
        contact:con
      }),
      address_details:cust_address({
        add:ad
      }),
      varified:false,
      status:0,
      weight:0,
      cust_id:msg.sender
    });

  }

  //for get total number of not varified customer count
  function getNonVerifiredCustomersCount() public view returns(uint){
    //require(validBankAddress(msg.sender);,"Only banks can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    return non_verified_customers_adresses.length;
  }
  //for get total number of  varified customer count
  function getVerifiredCustomersCount() public view returns(uint){
    //require(validBankAddress(msg.sender);,"Only banks can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    return verified_customers_adresses.length;
  }

  //for get the details of specific customer based on their number which they order they register themself
  function getNonVerifiredCustomers(uint custnumber) public view returns(uint,address,string memory,string memory,string memory){
    //require(validBankAddress(msg.sender);,"Only banks can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    require(custnumber<=getNonVerifiredCustomersCount(),"please enter valid customers number");//for checking if cutomer number valid or not
    customer memory c= all_customers[non_verified_customers_adresses[custnumber-1]];
    return (custnumber,c.cust_id,c.identity_details.name,c.identity_details.contact,c.address_details.add);
  }

  //customer verficaton stage based on their number which they order they register themself
  function verificationDoneCusomer(uint custnumber) public {
    //require(validBankAddress(msg.sender);,"Only banks can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    require(custnumber<=getNonVerifiredCustomersCount(),"please enter valid customers number");
    require(!all_customers[non_verified_customers_adresses[custnumber]].varified,"Customer already verified");
    all_customers[non_verified_customers_adresses[custnumber]].varified=true;
    all_customers[non_verified_customers_adresses[custnumber]].status=1;
    verified_customers_adresses.push(non_verified_customers_adresses[custnumber]);
  }

  //for getting the verified customer details base on their addresses
  function getVerifireCustomers(address adr) public view returns(address,string memory,string memory,string memory){
    //require(validBankAddress(msg.sender)|| all_customers[adr].cust_id==msg.sender,"Only banks or owner can use this function");
    require(authority==msg.sender || all_customers[adr].cust_id==msg.sender ,"Only authority or owner can use this function");
    require(all_customers[adr].varified,"Customer does not exits or may be not verified");
    require(all_customers[adr].status==1,"Customer is disabled");//for check account avaliablity
    customer memory c= all_customers[adr];
    return (c.cust_id,c.identity_details.name,c.identity_details.contact,c.address_details.add);
  }

  //for geting the verified customer address base on there oreder
  function getVerifiedCutomerAddress(uint i) public view returns(address,string memory){
    //require(validBankAddress(msg.sender)|| all_customers[adr].cust_id==msg.sender,"Only banks or owner can use this function");
    address adr= all_customers[verified_customers_adresses[i]].cust_id;
    require(authority==msg.sender ||adr==msg.sender ,"Only authority or owner can use this function");
    return (verified_customers_adresses[i],all_customers[adr].identity_details.name);
    }
//for update details of one customer
  function updateCustomer(address adr,string memory nm,string memory con,string memory ad) public payable returns(address){
    //require(validBankAddress(msg.sender)|| all_customers[adr].cust_id==msg.sender,"Only banks or owner can use this function");
    require(authority==msg.sender || adr==msg.sender,"only authority and owner can update");
    all_customers[adr]=customer({
      identity_details:identity({
        name:nm,
        contact:con
      }),
      address_details:cust_address({
        add:ad
      }),
      varified:false,
      status:0,
      weight:0,
      cust_id:msg.sender
    });
    if(authority==msg.sender){
      all_customers[adr].varified=true;
    }else{
      non_verified_customers_adresses.push(msg.sender);
    }
    return all_customers[msg.sender].cust_id;
  }
//for disabling an active account
  function disableCustomer(address cust)public{
    //require(validBankAddress(msg.sender)|| all_customers[adr].cust_id==msg.sender,"Only banks or owner can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    require(all_customers[cust].status==1,"Customer is already disabled or not added");
    all_customers[cust].status=3;
  }
//for enabling an active account
  function enableCustomer(address cust)public{
    //require(validBankAddress(msg.sender)|| all_customers[adr].cust_id==msg.sender,"Only banks or owner can use this function");
    require(authority==msg.sender,"Only authority can use this function");
    require(all_customers[cust].status==3,"Customer is already enabled or not added");
    all_customers[cust].status=1;
  }

}
