use FlyAirDB
go
drop table if exists Booking
go 
create table dbo.Booking(
    BookingId int not null identity primary key,
    FlightNum char(6) not null 
        constraint ck_Booking_flight_number_must_start_with_Fly_then_3_digits_starting_from_001 check((FlightNum like 'Fly[0-9][0-9][0-9]') and (right(FlightNum, 3) <> '000')),
    DepartureAirport char(3) not null
        constraint ck_Booking_departure_airport_must_be_3_letters check(DepartureAirport like '[a-z][a-z][a-z]'),
    DepartureCountry varchar(25) not null
        constraint ck_Booking_departure_country_cannot_be_blank check(DepartureCountry <> ''),
    DepartureTime datetime not null,
    ArrivalAirport char(3) not null
        constraint ck_Booking_arrival_airport_must_be_3_letters check(ArrivalAirport like '[a-z][a-z][a-z]'),
    ArrivalCountry varchar(25) not null
        constraint ck_Booking_arrival_country_cannot_be_blank check(ArrivalCountry <> ''),
    ArrivalTime datetime not null,
    PassengerName varchar(50) not null
        constraint ck_Booking_passenger_name_cannot_be_blank check(PassengerName <> ''),
    PassengerDOB date not null,
    PassengerAddress varchar(100) not null
        constraint ck_Booking_passenger_address_cannot_be_blank check(PassengerAddress <> ''),
    BookedDate date null,
    PassportNum varchar(9) null
        constraint ck_Booking_passport_num_must_be_9_digits_and_first_cannot_be_0 
            check((len(PassportNum) = 9) and (PassportNum not like '%[^0-9]%') and (PassportNum not like '0%')),
    PassportIssueDate date null,
    PassportExpiryDate date null,
    PassportNationality varchar(25) null
        constraint Booking_passport_nationality_cannot_be_blank check(PassportNationality <> ''),
    CheckedInTime datetime null,
    
    -- Date constraints
    constraint ck_Booking_passport_expiry_date_must_be_9_years_6_months_after_passport_issue_date_if_age_is_16_or_more_otherwise_5_years_after
        check( (PassportIssueDate >= dateadd(year, 16, PassengerDOB) and PassportExpiryDate = dateadd(year, 9, dateadd(month, 6, PassportIssueDate))) 
        or (PassportIssueDate < dateadd(year, 16, PassengerDOB) and PassportExpiryDate = dateadd(year, 5, PassportIssueDate))),
	constraint ck_Booking_passport_issue_date_cannot_be_before_passenger_dob check(PassengerDOB <= PassportIssueDate),
	constraint ck_Booking_passport_booked_date_cannot_be_before_passport_issue_date check(PassportIssueDate <= BookedDate),
	constraint ck_Booking_checked_in_time_cannot_be_before_booked_date check((BookedDate <= CheckedInTime) or CheckedInTime is null),
    constraint ck_Booking_passenger_age_must_be_between_16_and_90 
		check(DepartureTime between dateadd(year, 16, PassengerDOB) and dateadd(year, 91, PassengerDOB)),
    constraint ck_Booking_booked_date_must_be_between_1_year_and_1_hour_before_departure_time 
		check(BookedDate between dateadd(year, -1, DepartureTime) and dateadd(hour, -1, DepartureTime)),
    constraint ck_Booking_checked_in_time_must_be_between_30_days_and_1_hour_before_departure_time 
		check(CheckedInTime between dateadd(day, -30, DepartureTime) and dateadd(hour, -1, DepartureTime)),
    constraint ck_Booking_arrival_time_must_be_after_departure_time check(ArrivalTime > DepartureTime),
	constraint ck_passport_is_or_will_be_expired_on_departure_date
		check(PassportExpiryDate > DepartureTime or ArrivalCountry in (DepartureCountry, PassportNationality)),
    
	--All or non constraints
	constraint ck_Booking_passport_num_passport_issue_date_passport_nationality_and_checked_in_time_must_all_either_be_completed_or_null
        check((PassportNum is null and PassportIssueDate is null and PassportNationality is null and PassportExpiryDate is null)
        or (PassportNum is not null and PassportIssueDate is not null and PassportNationality is not null and PassportExpiryDate is not null)),

	--Unique Constraints
    constraint u_Booking_one_passenger_cannot_book_2_tickets_on_the_same_flight 
        unique (FlightNum, DepartureTime, PassengerName, PassengerDOB, PassengerAddress),

    --add constraint to ensur that we dont reuse flight info while its in use
)