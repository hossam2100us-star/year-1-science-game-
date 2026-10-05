/// Curriculum namespace for progress records (AUD-023).
///
/// Unit and quiz IDs (`unit_01`, `quiz_04`) are unique only inside one
/// curriculum. Stored attempts and journeys carry this ID, so adding a
/// second school year or subject later cannot collide with Year 1 science.
const currentCurriculum = 'y1.science';
