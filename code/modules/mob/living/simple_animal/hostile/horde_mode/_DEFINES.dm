#define HORDE_MODE_HEALTH_LESSER_DRONE 150
#define HORDE_MODE_HEALTH_VERY_LOW 250
#define HORDE_MODE_HEALTH_LOW 300
#define HORDE_MODE_HEALTH_MEDIUM 375
#define HORDE_MODE_HEALTH_HIGH 500
#define HORDE_MODE_HEALTH_VERY_HIGH  750
#define HORDE_MODE_HEALTH_BOSS 2000

#define HORDE_MODE_SPEED_VERY_SLOW 4.75
#define HORDE_MODE_SPEED_SLOW 4.5
#define HORDE_MODE_SPEED_NORMAL 4
#define HORDE_MODE_SPEED_FAST 3.75
#define HORDE_MODE_SPEED_VERY_FAST 3.5
#define HORDE_MODE_SPEED_RUNNER 3
#define HORDE_MODE_SPEED_INSANELY_FAST 1.5

#define HORDE_MODE_SPEED_MOD_MEDIUM 0.5
#define HORDE_MODE_SPEED_MOD_HIGH 0.75
#define HORDE_MODE_SPEED_MOD_EXTREMELY_HIGH 1.5

#define HORDE_MODE_ATTACK_DELAY_SLUGGISH (2.5 SECONDS)
#define HORDE_MODE_ATTACK_DELAY_NORMAL (1.5 SECONDS)
#define HORDE_MODE_ATTACK_DELAY_FAST (0.5 SECONDS)

#define HORDE_MODE_DAMAGE_EXTREMELY_LOW 10
#define HORDE_MODE_DAMAGE_VERY_LOW 15
#define HORDE_MODE_DAMAGE_LOW 20
#define HORDE_MODE_DAMAGE_MEDIUM 25
#define HORDE_MODE_DAMAGE_HIGH 30
#define HORDE_MODE_DAMAGE_VERY_HIGH 35

///this ability will be activated in the Life() proc
#define HORDE_MODE_ABILITY_ACTIVE 0
///this ability will be activated everytime a target gets hit
#define HORDE_MODE_ABILITY_POSTATTACK 1
///this ability will be activated everytime the mob is about to attack
#define HORDE_MODE_ABILITY_PREATTACK 2
///this ability will be activated under specific circumstances
#define HORDE_MODE_ABILITY_SPECIAL 3