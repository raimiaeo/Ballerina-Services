import ballerina/http;
import ballerina/sql;

service /api on new http:Listener(3000) {

    //Resouce Function to Retrieve all programmes due for review
    resource function get review_due() returns Reviews[]|error {
        stream<Reviews, sql:Error?> reviewsStream = db->query(`
            SELECT *
            FROM Reviews r
            WHERE r.review_due_date <= CURRENT_DATE
        `);

        Reviews[] reviewList = [];
        check from Reviews reviews in reviewsStream
            do {
                reviewList.push(reviews);
            };

        // if reviewList.length() == 0 {
        //     return error("No Programme is Due");
        // }

        return reviewList;
    }

    //Resource function to Delete a programme by programme code and returns the removed Programme.
    resource function delete delete_programme/[string programme_code]() returns Programmes[]|error {
        // Retrieve the programme details before deletion
        stream<Programmes, sql:Error?> programmeStream = db->query(`
        SELECT * 
        FROM Programmes
        WHERE programme_code = ${programme_code}
    `);

        Programmes[] programmeList = [];
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // Check if the programme exists
        if programmeList.length() == 0 {
            return error("Programme not found.");
        }

        // First, delete related entries in the Courses table
        _ = check db->execute(`
        DELETE FROM Courses
        WHERE programme_code = ${programme_code}
    `);

        // Then, delete the programme
        _ = check db->execute(`
        DELETE FROM Programmes
        WHERE programme_code = ${programme_code}
    `);

        // Return the deleted programme details
        return programmeList;
    }

    //Resource function to Retrieve all programmes that belong to the same faculty
    resource function get faculty_programme/[string faculty]() returns Programmes[]|error {
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT *
            FROM Programmes p
            WHERE p.faculty = ${faculty}
        `);

        Programmes[] programmeList = [];
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // if reviewList.length() == 0 {
        //     return error("No Programme is Due");
        // }

        return programmeList;
    }

// Resource function to retrieve programme details by programme_code
    resource function get ./[string programme_code]() returns json|error {
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT * 
            FROM Programmes
            WHERE programme_code = ?
        `, programme_code);

        Programmes[] programmeList = [];
        
        // Collecting programmes from the stream
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // Check if any programmes were found
        if programmeList.length() > 0 {
            // Return the list of programmes as JSON
            return programmeList;
        } else
{
            // Return an error if no programme was found
            return { "message": "No programme found with code: " + programme_code };
        }
    }
}

    // Resource function to add a new programme
    resource function post add_programme(Programmes programme) returns Programmes[]|error {
        // Insert the new programme into the database
        _ = check db->execute(`
                INSERT INTO Programmes (programme_code, programme_name, NQF_level, faculty, department)
                VALUES (${programme.programme_code}, ${programme.programme_name}, ${programme.NQF_level}, ${programme.faculty}, ${programme.department})
            `);

        // Query the database for the newly added programme
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT * FROM Programmes WHERE programme_code = ${programme.programme_code}
        `);

        // Collect results from the stream into a list
        Programmes[] programmeList = [];
        check from Programmes programmes in programmeStream
            do {
                programmeList.push(programmes);
            };

        // If no results are found, return an error
        if (programmeList.length() == 0) {
            return error("Error adding Programme: " + programme.programme_code.toString() + ", " + programme.programme_name.toString());
        }

        return programmeList;
    }

}
