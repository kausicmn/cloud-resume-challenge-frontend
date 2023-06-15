var containter=document.querySelector(".website-count")
// var visitcount=localStorage.getItem("page_view")
// if(visitcount){
//     visitcount=Number(visitcount)+1;
//     localStorage.setItem("page_view",visitcount);

// }
// else
// {
//     visitcount=1;
//     localStorage.setItem("page_view",visitcount);
// }
// //containter.innerHTML=visitcount

// async function count(url){
//     const response = await fetch();
//     var data = await response.json();
//     }
const url="https://counter-api.kausicmn.com/example" 
async function counter(url)
{
    const response = await fetch(url)
    let data = await response.json()
    containter.innerHTML=`Views: ${data}`
    
}
counter(url);
 