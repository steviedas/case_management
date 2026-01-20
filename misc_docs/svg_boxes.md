export const TRAIN_CONFIG_3_CAR = {
    id: '3-car',
    imageSrc: trainImage,
    width: 1874.13, // ratio must map to original image dimensions e.g. 1874.13 / 112.01 = 16.73
    height: 112.01,
    zones: [
        // ==========================================
        // ENGINE SYSTEMS
        // ==========================================
        {
            id: 'engine-car-1',
            name: 'Engine (Car 1)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.ENGINE,
            shapes: [{ type: 'rect', x: 299.88, y: 67.31, width: 93.96, height: 43.43 }], // TODO: adjust dimensions
        },
        {
            id: 'engine-car-2',
            name: 'Engine (Car 2)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.ENGINE,
            shapes: [{ type: 'rect', x: 873.61, y: 67.31, width: 86.32, height: 43.43 }], // TODO: adjust dimensions
        },
        {
            id: 'engine-car-3',
            name: 'Engine (Car 3)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.ENGINE,
            shapes: [{ type: 'rect', x: 1479.92, y: 67.31, width: 92.22, height: 43.43 }], // TODO: adjust dimensions
        },

        // ==========================================
        // TRANSMISSION SYSTEMS
        // ==========================================
        {
            id: 'transmission-car-1',
            name: 'Transmission (Car 1)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.TRANSMISSION,
            shapes: [{ type: 'rect', x: 394.98, y: 67.31, width: 100.03, height: 43.43 }],
        },
        {
            id: 'transmission-car-2',
            name: 'Transmission (Car 2)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.TRANSMISSION,
            shapes: [{ type: 'rect', x: 772.75, y: 67.31, width: 100.03, height: 43.43 }],
        },
        {
            id: 'transmission-car-3',
            name: 'Transmission (Car 3)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.TRANSMISSION,
            shapes: [{ type: 'rect', x: 1378.38, y: 67.31, width: 100.03, height: 43.43 }],
        },

        // ==========================================
        // AIR SYSTEMS
        // ==========================================
        {
            id: 'air-car-1',
            name: 'Air System (Car 1)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.AIR,
            shapes: [{ type: 'rect', x: 176.34, y: 67.31, width: 46.3, height: 43.43 }],
        },
        {
            id: 'air-car-2',
            name: 'Air System (Car 2)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.AIR,
            shapes: [{ type: 'rect', x: 999.8, y: 67.31, width: 42.1, height: 43.43 }],
        },
        {
            id: 'air-car-3',
            name: 'Air System (Car 3)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.AIR,
            shapes: [{ type: 'rect', x: 1649, y: 67.31, width: 48.79, height: 43.43 }],
        },

        // ==========================================
        // HYDROSTATIC SYSTEMS
        // ==========================================
        {
            id: 'hydro-car-1',
            name: 'Hydrostatic System (Car 1)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.HYDRO,
            shapes: [{ type: 'rect', x: 226.36, y: 67.31, width: 72.38, height: 43.43 }],
        },
        {
            id: 'hydro-car-2',
            name: 'Hydrostatic System (Car 2)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.HYDRO,
            shapes: [{ type: 'rect', x: 960.59, y: 67.31, width: 37.19, height: 43.43 }],
        },
        {
            id: 'hydro-car-3',
            name: 'Hydrostatic System (Car 3)',
            fillColor: INACTIVE_ZONE_COLOR,
            activeColor: COLORS_TRAIN_CONFIG_3_CAR.HYDRO,
            shapes: [{ type: 'rect', x: 1575.41, y: 67.31, width: 71.05, height: 43.43 }],
        },
    ],
};