<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "BloodDonationDB";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) { die("Connection failed: " . $conn->connect_error); }

$message = "";




// === Register Donor ===
if (isset($_POST['register_donor'])) {
  $name = trim($_POST['donor_name']);
  $age = intval($_POST['donor_age']);
  $bg = $_POST['donor_bg'];
  $contact = trim($_POST['donor_contact']);
  $lastdate = $_POST['donor_date'];

  $exists = $conn->query("SELECT * FROM Donors WHERE Name='$name' AND Contact='$contact'");
  if ($exists->num_rows > 0) {
    $message = "❌ Donor already exists.";
  } else if ($age < 18) {
    $message = "❌ Donor must be at least 18 years old!";
  } else {
    $conn->query("INSERT INTO Donors (Name, Age, BloodGroup, Contact, LastDonationDate)
      VALUES ('$name', $age, '$bg', '$contact', '$lastdate')");
    $message = "✅ New donor registered: $name ($bg)";
  }
}

// === Register Recipient ===
if (isset($_POST['register_recipient'])) {
  $name = trim($_POST['recipient_name']);
  $age = intval($_POST['recipient_age']);
  $bg = $_POST['recipient_bg'];
  $contact = trim($_POST['recipient_contact']);
  $required = intval($_POST['recipient_units']);

  $exists = $conn->query("SELECT * FROM Recipients WHERE Name='$name' AND Contact='$contact'");
  if ($exists->num_rows > 0) {
    $message = "❌ Recipient already exists.";
  } else {
    $conn->query("INSERT INTO Recipients (Name, Age, BloodGroup, Contact, BloodRequired, Status)
      VALUES ('$name', $age, '$bg', '$contact', $required, 'Pending')");
    $message = "✅ Blood request registered: $name ($bg) needs $required units.";
  }
}

// === Add Donation ===
if (isset($_POST['add_donation'])) {
  $donorid = intval($_POST['donor_id']);
  $units = intval($_POST['donation_units']);
  $date = $_POST['donation_date'];

  $res = $conn->query("SELECT BloodGroup FROM Donors WHERE DonorID=$donorid");
  if ($res->num_rows > 0) {
    $row = $res->fetch_assoc();
    $bg = $row['BloodGroup'];
    $conn->query("INSERT INTO Donations (DonorID, BloodGroup, DonationDate, Units)
      VALUES ($donorid, '$bg', '$date', $units)");
    $conn->query("UPDATE BloodInventory SET UnitsAvailable = UnitsAvailable + $units WHERE BloodGroup='$bg'");
    $message = "✅ Donation recorded: $units unit(s) added for $bg.";
  } else {
    $message = "❌ Invalid Donor ID.";
  }
}

// === Process Request ===
if (isset($_POST['process_request'])) {
  $reqid = intval($_POST['request_id']);
  $result = $conn->query("SELECT BloodGroup, BloodRequired FROM Recipients WHERE RecipientID=$reqid AND Status='Pending'");
  if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $bg = $row['BloodGroup'];
    $required = intval($row['BloodRequired']);

    $stock = $conn->query("SELECT UnitsAvailable FROM BloodInventory WHERE BloodGroup='$bg'");
    $units = $stock->fetch_assoc()['UnitsAvailable'];

    if ($units >= $required) {
      $conn->query("UPDATE BloodInventory SET UnitsAvailable = UnitsAvailable - $required WHERE BloodGroup='$bg'");
      $conn->query("UPDATE Recipients SET Status='Approved' WHERE RecipientID=$reqid");
      $message = "✅ Request ID $reqid approved.";
    } else {
      $conn->query("UPDATE Recipients SET Status='Rejected' WHERE RecipientID=$reqid");
      $message = "⚠️ Not enough stock! Request ID $reqid rejected.";
    }
  } else {
    $message = "❌ Request not found or already processed.";
  }
}
?>

<!DOCTYPE html>
<html>
<head>
  <title>Blood Donation Management System</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header>
    <div class="header-left">
      <h1>🩸 Blood Donation Management System</h1>
      <p class="intro">Internship | Naresh D | B.Tech AI & DS | MKCE Karur | ID: 927623bad067</p>
    </div>
    <div class="profile">
      <img src="naresh.jpg" alt="Naresh D" class="profile-pic">
      <p class="badge">Naresh D</p>
    </div>
  </header>


  <div class="tabs">
    <button onclick="showTab('user')">User Side</button>
    <button onclick="showTab('bank')">Blood Bank Side</button>
  </div>

  <?php if ($message) echo "<p class='message'>$message</p>"; ?>

  <div id="user" class="tab-content">
    <div class="block">
      <h2>Register Donor</h2>
      <form method="post" onsubmit="return validateDonor();">
        <input type="text" name="donor_name" placeholder="Name" required>
        <input type="date" id="donor_dob" onchange="calcDonorAge()" required>
        <input type="number" name="donor_age" id="donor_age" placeholder="Age" readonly required>
        <select name="donor_bg" required>
          <option value="">-- Blood Group --</option>
          <option>O+</option><option>A+</option><option>B+</option><option>AB+</option>
          <option>O-</option><option>A-</option><option>B-</option><option>AB-</option>
        </select>
        <input type="text" name="donor_contact" placeholder="Contact" required>
        <input type="date" name="donor_date" required>
        <button type="submit" name="register_donor">Register Donor</button>
      </form>
    </div>

    <div class="block">
      <h2>Register Recipient</h2>
      <form method="post">
        <input type="text" name="recipient_name" placeholder="Name" required>
        <input type="number" name="recipient_age" placeholder="Age" min="0" required>
        <select name="recipient_bg" required>
          <option value="">-- Blood Group --</option>
          <option>O+</option><option>A+</option><option>B+</option><option>AB+</option>
          <option>O-</option><option>A-</option><option>B-</option><option>AB-</option>
        </select>
        <input type="text" name="recipient_contact" placeholder="Contact" required>
        <input type="number" name="recipient_units" placeholder="Units Required" min="1" required>
        <button type="submit" name="register_recipient">Request Blood</button>
      </form>
    </div>
  </div>

  <div id="bank" class="tab-content" style="display:none;">
    <div class="block">
      <h2>Record Donation</h2>
      <form method="post">
        <select name="donor_id" required>
          <option value="">-- Select Donor --</option>
          <?php
            $donors = $conn->query("SELECT DonorID, Name FROM Donors");
            while($d = $donors->fetch_assoc()) {
              echo "<option value='{$d['DonorID']}'>{$d['Name']} (ID: {$d['DonorID']})</option>";
            }
          ?>
        </select>
        <input type="number" name="donation_units" placeholder="Units Donated" min="1" required>
        <input type="date" name="donation_date" required>
        <button type="submit" name="add_donation">Add Donation</button>
      </form>
    </div>

    <div class="block">
      <h2>Process Request</h2>
      <form method="post">
        <input type="number" name="request_id" placeholder="Request ID" required>
        <button type="submit" name="process_request">Process</button>
      </form>
    </div>

    <div class="reports">
      <h2>Blood Inventory</h2>
      <table>
        <tr><th>Blood Group</th><th>Units Available</th></tr>
        <?php
          $inv = $conn->query("SELECT * FROM BloodInventory");
          while($row = $inv->fetch_assoc()) {
            echo "<tr><td>{$row['BloodGroup']}</td><td>{$row['UnitsAvailable']}</td></tr>";
          }
        ?>
      </table>

      <h2>Donor Statistics</h2>
      <table>
        <tr><th>Blood Group</th><th>Total Donors</th></tr>
        <?php
          $stats = $conn->query("SELECT BloodGroup, COUNT(*) as Total FROM Donors GROUP BY BloodGroup");
          while($row = $stats->fetch_assoc()) {
            echo "<tr><td>{$row['BloodGroup']}</td><td>{$row['Total']}</td></tr>";
          }
        ?>
      </table>

      <h2>Donation History</h2>
      <table>
        <tr><th>Name</th><th>Blood Group</th><th>Units</th><th>Date</th></tr>
        <?php
          $hist = $conn->query("SELECT Donors.Name, Donations.BloodGroup, Donations.Units, Donations.DonationDate
            FROM Donations JOIN Donors ON Donations.DonorID = Donors.DonorID ORDER BY Donations.DonationDate DESC");
          while($row = $hist->fetch_assoc()) {
            echo "<tr><td>{$row['Name']}</td><td>{$row['BloodGroup']}</td><td>{$row['Units']}</td><td>{$row['DonationDate']}</td></tr>";
          }
        ?>
      </table>

      <h2>Requests Status</h2>
      <table>
        <tr><th>Request ID</th><th>Name</th><th>Blood Group</th><th>Units</th><th>Status</th></tr>
        <?php
          $reqs = $conn->query("SELECT * FROM Recipients ORDER BY RecipientID DESC");
          while($row = $reqs->fetch_assoc()) {
            echo "<tr><td>{$row['RecipientID']}</td><td>{$row['Name']}</td><td>{$row['BloodGroup']}</td><td>{$row['BloodRequired']}</td><td>{$row['Status']}</td></tr>";
          }
        ?>
      </table>
    </div>
  </div>

  <script>
    function showTab(tab) {
      document.getElementById('user').style.display = (tab === 'user') ? 'block' : 'none';
      document.getElementById('bank').style.display = (tab === 'bank') ? 'block' : 'none';
    }
    function calcDonorAge() {
      const dob = document.getElementById('donor_dob').value;
      if (dob) {
        const today = new Date();
        const birth = new Date(dob);
        let age = today.getFullYear() - birth.getFullYear();
        const m = today.getMonth() - birth.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
        document.getElementById('donor_age').value = age;
      }
    }
    function validateDonor() {
      const age = document.getElementById('donor_age').value;
      if (age < 18) { alert("Must be 18+ to donate."); return false; }
      return true;
    }
  </script>
</body>
</html>
