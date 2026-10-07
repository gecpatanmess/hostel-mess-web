async function fix() {
    const res = await fetch('https://hostel-mess-21845-default-rtdb.firebaseio.com/hostelData/students.json');
    const data = await res.json();
    
    const fixedData = data.filter(s => s !== null);
    
    const hasDax = fixedData.some(s => s.name === 'Patel Dax Bhaveshkumar');
    if (!hasDax) {
        fixedData.push({
            name: 'Patel Dax Bhaveshkumar',
            roomNo: '110',
            email: '',
            photoUrl: '',
            pin: ''
        });
        fixedData.sort((a,b) => a.roomNo.localeCompare(b.roomNo));
    }
    
    await fetch('https://hostel-mess-21845-default-rtdb.firebaseio.com/hostelData/students.json', {
        method: 'PUT',
        body: JSON.stringify(fixedData)
    });
    console.log("Fixed!");
}
fix();
